//
// SAChannelMatchManager.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/8/29.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAChannelMatchManager.h"
#import "SAConstants+Private.h"
#import "SAIdentifier.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAValidator.h"
#import "SAAlertController.h"
#import "SAURLUtils.h"
#import "SAReachability.h"
#import "SALog.h"
#import "SAFileStore.h"
#import "SAJSONUtil.h"

NSString * const kSAChannelDebugFlagKey = @"com.sensorsdata.channeldebug.flag";
NSString * const kSAChannelDebugInstallEventName = @"$ChannelDebugInstall";
NSString * const kSAEventPropertyChannelDeviceInfo = @"$channel_device_info";
NSString * const kSAEventPropertyUserAgent = @"$user_agent";
NSString * const kSAEventPropertyChannelCallbackEvent = @"$is_channel_callback_event";

@interface SAChannelMatchManager ()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, strong) NSMutableSet<NSString *> *trackChannelEventNames;

@end

@implementation SAChannelMatchManager

#pragma mark -

- (NSMutableSet<NSString *> *)trackChannelEventNames {
    if (!_trackChannelEventNames) {
        _trackChannelEventNames = [[NSMutableSet alloc] init];
        NSSet *trackChannelEvents = (NSSet *)[SAFileStore unarchiveWithFileName:kSAEventPropertyChannelDeviceInfo];
        if (trackChannelEvents) {
            [_trackChannelEventNames unionSet:trackChannelEvents];
        }
    }
    return _trackChannelEventNames;
}

#pragma mark - indicator view
- (void)showIndicator {
    _window = [self alertWindow];
    _window.windowLevel = UIWindowLevelAlert + 1;
    UIViewController *controller = [[SAAlertController alloc] init];
    _window.rootViewController = controller;
    _window.hidden = NO;
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _indicator.center = CGPointMake(_window.center.x, _window.center.y);
    [_window.rootViewController.view addSubview:_indicator];
    [_indicator startAnimating];
}

- (void)hideIndicator {
    [_indicator stopAnimating];
    _indicator = nil;
    _window = nil;
}

- (UIWindow *)alertWindow {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000)
    if (@available(iOS 13.0, *)) {
        __block UIWindowScene *scene = nil;
        [[UIApplication sharedApplication].connectedScenes.allObjects enumerateObjectsUsingBlock:^(UIScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIWindowScene class]]) {
                scene = (UIWindowScene *)obj;
                *stop = YES;
            }
        }];
        if (scene) {
            return [[UIWindow alloc] initWithWindowScene:scene];
        }
    }
#endif
    return [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

#pragma mark - 渠道联调诊断标记
/// 客户是否触发过激活事件
- (BOOL)isAppInstalled {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    return [userDefault boolForKey:SA_HAS_TRACK_INSTALLATION_DISABLE_CALLBACK] || [userDefault boolForKey:SA_HAS_TRACK_INSTALLATION];
}

/// 客户可以使用渠道联调诊断功能
- (BOOL)isValidForChannelDebug {
    if (![self isAppInstalled]) {
        // 当未触发过激活事件时，可以使用联调诊断功能
        return YES;
    }
    return [[NSUserDefaults standardUserDefaults] boolForKey:kSAChannelDebugFlagKey];
}

/// 当前获取到的设备 ID 为有效值
- (BOOL)isValidOfDeviceInfo {
    return ([SAIdentifier idfa].length > 0 || [self CAIDInfo].allKeys > 0);
}

#pragma mark - 激活事件
- (void)trackAppInstall:(NSString *)event properties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback {

    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *userDefaultsKey = disableCallback ? SA_HAS_TRACK_INSTALLATION_DISABLE_CALLBACK : SA_HAS_TRACK_INSTALLATION;
    BOOL hasTrackInstallation = [userDefault boolForKey:userDefaultsKey];
    if (hasTrackInstallation) {
        return;
    }

    // 记录激活事件是否获取到了有效的设备 ID 信息，设备 ID 信息有效时后续可以使用联调诊断功能
    [userDefault setBool:[self isValidOfDeviceInfo] forKey:kSAChannelDebugFlagKey];

    // 激活事件 - 根据 disableCallback 记录是否触发过激活事件
    [userDefault setBool:YES forKey:userDefaultsKey];
    [userDefault synchronize];

    NSMutableDictionary *eventProps = [NSMutableDictionary dictionary];
    if ([SAValidator isValidDictionary:properties]) {
        [eventProps addEntriesFromDictionary:properties];
    }
    if (disableCallback) {
        eventProps[SA_EVENT_PROPERTY_APP_INSTALL_DISABLE_CALLBACK] = @YES;
    }
    [self handleAppInstallEvent:event properties:eventProps];
}

- (void)trackChannelDebugInstallEvent {
    [self handleAppInstallEvent:kSAChannelDebugInstallEventName properties:nil];
}

- (void)handleAppInstallEvent:(NSString *)event properties:(NSDictionary *)properties {
    NSMutableDictionary *eventProps = [NSMutableDictionary dictionaryWithDictionary:properties];
    eventProps[SA_EVENT_PROPERTY_APP_INSTALL_SOURCE] = [self appInstallSource];

    if ([eventProps[kSAEventPropertyUserAgent] length] == 0) {
        eventProps[kSAEventPropertyUserAgent] = [self simulateUserAgent];
    }
    [self trackAppInstallEvent:event properties:eventProps];
}

- (NSString *)appInstallSource {
    NSMutableDictionary *sources = [NSMutableDictionary dictionary];
    [sources addEntriesFromDictionary:[self CAIDInfo]];
    sources[@"idfa"] = [SAIdentifier idfa];
    sources[@"idfv"] = [SAIdentifier idfv];
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *key in sources.allKeys) {
        [result addObject:[NSString stringWithFormat:@"%@=%@", key, sources[key]]];
    }
    return [result componentsJoinedByString:@"##"];
}

- (NSDictionary *)CAIDInfo {
    Class cla = NSClassFromString(@"SACAIDUtils");
    SEL sel = NSSelectorFromString(@"CAIDInfo");
    if ([cla respondsToSelector:sel]) {
        return ((NSDictionary * (*)(id, SEL))[cla methodForSelector:sel])(cla, sel);
    }
    return nil;
}

- (void)trackAppInstallEvent:(NSString *)event properties:(NSDictionary *)properties {
    // 先发送 track
    SensorsAnalyticsSDK *sdk = [SensorsAnalyticsSDK sharedInstance];
    SAPresetEventObject *object = [[SAPresetEventObject alloc] initWithEventId:event];
    [sdk asyncTrackEventObject:object properties:properties];

    NSMutableDictionary *profileProps = [NSMutableDictionary dictionary];
    [profileProps addEntriesFromDictionary:properties];
    // 用户属性中不需要添加 $ios_install_disable_callback，这里主动移除掉
    [profileProps removeObjectForKey:SA_EVENT_PROPERTY_APP_INSTALL_DISABLE_CALLBACK];
    // 再发送 profile_set_once
    [profileProps setValue:[NSDate date] forKey:SA_EVENT_PROPERTY_APP_INSTALL_FIRST_VISIT_TIME];
    if (sdk.configOptions.enableMultipleChannelMatch) {
        [sdk set:profileProps];
    } else {
        [sdk setOnce:profileProps];
    }
    [sdk flush];
}

#pragma mark - 附加渠道信息
- (void)trackChannelWithEventObject:(SABaseEventObject *)obj properties:(nullable NSDictionary *)propertyDict {
    if (self.configOptions.enableAutoAddChannelCallbackEvent) {
        return [SensorsAnalyticsSDK.sharedInstance trackEventObject:obj properties:propertyDict];
    }
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:propertyDict];
    // ua
    if ([propertyDict[kSAEventPropertyUserAgent] length] == 0) {
        properties[kSAEventPropertyUserAgent] = [self simulateUserAgent];
    }
    // idfa
    NSString *idfa = [SAIdentifier idfa];
    if (idfa) {
        [properties setValue:[NSString stringWithFormat:@"idfa=%@", idfa] forKey:kSAEventPropertyChannelDeviceInfo];
    } else {
        [properties setValue:@"" forKey:kSAEventPropertyChannelDeviceInfo];
    }
    // callback
    [properties addEntriesFromDictionary:[self channelPropertiesWithEvent:obj.event]];

    [SensorsAnalyticsSDK.sharedInstance trackEventObject:obj properties:properties];
}

- (NSDictionary *)channelPropertiesWithEvent:(NSString *)event {
    BOOL isNotContains = ![self.trackChannelEventNames containsObject:event];
    if (isNotContains && event) {
        [self.trackChannelEventNames addObject:event];
        [self archiveTrackChannelEventNames];
    }
    return @{kSAEventPropertyChannelCallbackEvent : @(isNotContains)};
}

- (void)archiveTrackChannelEventNames {
    [SAFileStore archiveWithFileName:kSAEventPropertyChannelDeviceInfo value:self.trackChannelEventNames];
}

- (NSDictionary *)channelInfoWithEvent:(NSString *)event {
    if (self.configOptions.enableAutoAddChannelCallbackEvent) {
        NSMutableDictionary *channelInfo = [NSMutableDictionary dictionaryWithDictionary:[self channelPropertiesWithEvent:event]];
        channelInfo[kSAEventPropertyChannelDeviceInfo] = @"1";
        return channelInfo;
    }
    return nil;
}

- (NSString *)simulateUserAgent {
    NSString *version = [UIDevice.currentDevice.systemVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString *model = UIDevice.currentDevice.model;
    return [NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile", model, version];
}

#pragma mark - handle URL
- (BOOL)canHandleURL:(NSURL *)url {
    NSDictionary *queryItems = [SAURLUtils queryItemsWithURL:url];
    NSString *monitorId = queryItems[@"monitor_id"];
    return [url.host isEqualToString:@"channeldebug"] && monitorId.length;
}

- (BOOL)handleURL:(NSURL *)url {
    if (![self canHandleURL:url]) {
        return NO;
    }

    SANetwork *network = [SensorsAnalyticsSDK sharedInstance].network;
    if (!network.serverURL.absoluteString.length) {
        [self showErrorMessage:@"数据接收地址错误，无法使用联调诊断工具"];
        return NO;
    }
    NSString *project = [SAURLUtils queryItemsWithURLString:url.absoluteString][@"project_name"] ?: @"default";
    BOOL isEqualProject = [network.project isEqualToString:project];
    if (!isEqualProject) {
        [self showErrorMessage:@"App 集成的项目与电脑浏览器打开的项目不同，无法使用联调诊断工具"];
        return NO;
    }
    // 如果是重连二维码功能，直接进入重连二维码流程
    if ([self isRelinkURL:url]) {
        [self showRelinkAlertWithURL:url];
        return YES;
    }
    // 展示渠道联调诊断询问弹窗
    [self showAuthorizationAlertWithURL:url];
    return YES;
}

#pragma mark - 重连二维码
- (BOOL)isRelinkURL:(NSURL *)url {
    NSDictionary *queryItems = [SAURLUtils queryItemsWithURL:url];
    return [queryItems[@"is_relink"] boolValue];
}

- (void)showRelinkAlertWithURL:(NSURL *)url {
    NSDictionary *queryItems = [SAURLUtils queryItemsWithURL:url];
    NSString *deviceId = [queryItems[@"device_code"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    // 重连二维码对应的设备信息
    NSMutableSet *deviceIdSet = [NSMutableSet setWithArray:[deviceId componentsSeparatedByString:@"##"]];
    // 当前设备的设备信息
    NSSet *installSourceSet = [NSSet setWithArray:[[self appInstallSource] componentsSeparatedByString:@"##"]];
    // 当 IDFV 、IDFA caid、last_caid 都不一致，且只有 caid_version 一致时会出现匹配错误的情况
    // 此场景在实际业务中出现概率较低，不考虑此问题
    [deviceIdSet intersectSet:installSourceSet];
    // 取交集，当交集不为空时，表示设备一致
    if (deviceIdSet.count > 0) {
        [self showChannelDebugInstall];
    } else {
        [self showErrorMessage:@"无法重连，请检查是否更换了联调手机"];
    }
}

#pragma mark - Auth Alert
- (void)showAuthorizationAlertWithURL:(NSURL *)url {
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"即将开启联调模式" message:nil preferredStyle:SAAlertControllerStyleAlert];
    __weak SAChannelMatchManager *weakSelf = self;
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
        __strong SAChannelMatchManager *strongSelf = weakSelf;
        if ([strongSelf isValidForChannelDebug] && [strongSelf isValidOfDeviceInfo]) {
            NSDictionary *qureyItems = [SAURLUtils queryItemsWithURL:url];
            [strongSelf uploadUserInfoIntoWhiteList:qureyItems];
        } else {
            [strongSelf showChannelDebugErrorMessage];
        }
    }];
    [alertController addActionWithTitle:@"取消" style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

- (void)uploadUserInfoIntoWhiteList:(NSDictionary *)qureyItems {
    if (![SAReachability sharedInstance].isReachable) {
        [self showErrorMessage:@"当前网络不可用，请检查网络！"];
        return;
    }
    NSURLComponents *components = SensorsAnalyticsSDK.sharedInstance.network.baseURLComponents;
    if (!components) {
        return;
    }
    components.query = nil;
    components.path = [components.path stringByAppendingPathComponent:@"/api/sdk/channel_tool/url"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
    request.timeoutInterval = 60;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:qureyItems];
    params[@"distinct_id"] = [[SensorsAnalyticsSDK sharedInstance] distinctId];
    params[@"has_active"] = @([self isAppInstalled]);
    params[@"device_code"] = [self appInstallSource];
    request.HTTPBody = [SAJSONUtil dataWithJSONObject:params];

    [self showIndicator];
    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        NSDictionary *dict;
        if (data) {
            dict = [SAJSONUtil JSONObjectWithData:data];
        }
        NSInteger code = [dict[@"code"] integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideIndicator];
            if (response.statusCode == 200) {
                // 只有当 code 为 1 时表示请求成功
                if (code == 1) {
                    [self showChannelDebugInstall];
                } else {
                    NSString *message = dict[@"message"];
                    SALogError(@"%@", message);
                    [self showErrorMessage:@"添加白名单请求失败，请联系神策技术支持人员排查问题！"];
                }
            } else {
                [self showErrorMessage:@"网络异常,请求失败！"];
            }
        });
    }];
    [task resume];
}

#pragma mark - ChannelDebugInstall Alert
- (void)showChannelDebugInstall {
    NSString *title = @"成功开启联调模式";
    NSString *content = @"此模式下不需要卸载 App，点击“激活”按钮可反复触发激活。";
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:content preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"激活" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
        [self trackChannelDebugInstallEvent];
        [self showChannelDebugInstall];
    }];
    [alertController addActionWithTitle:@"取消" style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

#pragma mark - Error Message
- (void)showChannelDebugErrorMessage {
    NSString *title = @"检测到“设备码为空”，可能的原因如下，请排查：";
    NSString *content = @"\n1. 手机系统设置中「隐私->广告-> 限制广告追踪」；\n\n2.若手机系统为 iOS 14 ，请联系研发人员确认 trackAppInstall 接口是否在 “跟踪” 授权之后调用。\n\n排查修复后，请重新扫码进行联调。\n\n3. 若集成了 CAID SDK，请联系研发人员确认 trackAppInstall 接口是否在 “getCAIDAsyncly” 授权之后调用。\n\n";
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:content preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

- (void)showErrorMessage:(NSString *)errorMessage {
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"提示" message:errorMessage preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

@end
