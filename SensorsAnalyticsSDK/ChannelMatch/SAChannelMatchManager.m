//
// SAChannelMatchManager.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/8/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
#import "SAStoreManager.h"
#import "SAJSONUtil.h"
#import "SensorsAnalyticsSDK+SAChannelMatch.h"
#import "SAApplication.h"
#import "SAProfileEventObject.h"
#import "SAPropertyPluginManager.h"
#import "SAChannelInfoPropertyPlugin.h"
#import "SACommonUtility.h"

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

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static SAChannelMatchManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAChannelMatchManager alloc] init];
    });
    return manager;
}

- (void)setConfigOptions:(SAConfigOptions *)configOptions {
    if ([SAApplication isAppExtension]) {
        configOptions.enableChannelMatch = NO;
    }
    _configOptions = configOptions;
    self.enable = configOptions.enableChannelMatch;

    // 注册渠道相关属性插件 Channel
    SAChannelInfoPropertyPlugin *channelInfoPropertyPlugin = [[SAChannelInfoPropertyPlugin alloc] init];
    [SensorsAnalyticsSDK.sharedInstance registerPropertyPlugin:channelInfoPropertyPlugin];
}

#pragma mark -

- (NSMutableSet<NSString *> *)trackChannelEventNames {
    if (!_trackChannelEventNames) {
        _trackChannelEventNames = [[NSMutableSet alloc] init];
        NSSet *trackChannelEvents = (NSSet *)[[SAStoreManager sharedInstance] objectForKey:kSAEventPropertyChannelDeviceInfo];
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

- (UIWindow *)alertWindow NS_EXTENSION_UNAVAILABLE("App Alert not supported for iOS extensions.") {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000)
    if (@available(iOS 13.0, *)) {
        __block UIWindowScene *scene = nil;
        [UIApplication.sharedApplication.connectedScenes.allObjects enumerateObjectsUsingBlock:^(UIScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
    SAStoreManager *manager = [SAStoreManager sharedInstance];
    return [manager boolForKey:kSAHasTrackInstallationDisableCallback] || [manager boolForKey:kSAHasTrackInstallation];
}

/// 客户可以使用渠道联调诊断功能
- (BOOL)isValidForChannelDebug {
    if (![self isAppInstalled]) {
        // 当未触发过激活事件时，可以使用联调诊断功能
        return YES;
    }
    return [[SAStoreManager sharedInstance] boolForKey:kSAChannelDebugFlagKey];
}

/// 当前获取到的设备 ID 为有效值
- (BOOL)isValidOfDeviceInfo {
    return [SAIdentifier idfa].length > 0;
}

- (BOOL)isTrackedAppInstallWithDisableCallback:(BOOL)disableCallback {
    NSString *key = disableCallback ? kSAHasTrackInstallationDisableCallback : kSAHasTrackInstallation;
    return [[SAStoreManager sharedInstance] boolForKey:key];
}

- (void)setTrackedAppInstallWithDisableCallback:(BOOL)disableCallback {
    SAStoreManager *manager = [SAStoreManager sharedInstance];
    NSString *userDefaultsKey = disableCallback ? kSAHasTrackInstallationDisableCallback : kSAHasTrackInstallation;

    // 记录激活事件是否获取到了有效的设备 ID 信息，设备 ID 信息有效时后续可以使用联调诊断功能
    [manager setBool:[self isValidOfDeviceInfo] forKey:kSAChannelDebugFlagKey];

    // 激活事件 - 根据 disableCallback 记录是否触发过激活事件
    [manager setBool:YES forKey:userDefaultsKey];
}

#pragma mark - 激活事件
- (void)trackAppInstall:(NSString *)event properties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback{
    // 采集激活事件
    SAPresetEventObject *eventObject = [[SAPresetEventObject alloc] initWithEventId:event];
    NSDictionary *eventProps = [self eventProperties:properties disableCallback:disableCallback];
    [SensorsAnalyticsSDK.sharedInstance trackEventObject:eventObject properties:eventProps];

    // 设置用户属性
    SAProfileEventObject *profileObject = [[SAProfileEventObject alloc] initWithType:kSAProfileSetOnce];
    NSDictionary *profileProps = [self profileProperties:properties];
    [SensorsAnalyticsSDK.sharedInstance trackEventObject:profileObject properties:profileProps];
}

- (NSDictionary *)eventProperties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if ([SAValidator isValidDictionary:properties]) {
        [result addEntriesFromDictionary:properties];
    }

    if (disableCallback) {
        result[kSAEventPropertyInstallDisableCallback] = @YES;
    }

    if ([result[kSAEventPropertyUserAgent] length] == 0) {
        result[kSAEventPropertyUserAgent] = [self simulateUserAgent];
    }

    result[kSAEventPropertyInstallSource] = [SACommonUtility appInstallSource];

    return result;
}

- (NSDictionary *)profileProperties:(NSDictionary *)properties {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if ([SAValidator isValidDictionary:properties]) {
        [result addEntriesFromDictionary:properties];
    }

    if ([result[kSAEventPropertyUserAgent] length] == 0) {
        result[kSAEventPropertyUserAgent] = [self simulateUserAgent];
    }

    result[kSAEventPropertyInstallSource] = [SACommonUtility appInstallSource];

    // 用户属性中不需要添加 $ios_install_disable_callback，这里主动移除掉
    // (也会移除自定义属性中的 $ios_install_disable_callback, 和原有逻辑保持一致)
    [result removeObjectForKey:kSAEventPropertyInstallDisableCallback];

    [result setValue:[NSDate date] forKey:kSAEventPropertyAppInstallFirstVisitTime];

    return result;
}

#pragma mark - 附加渠道信息
- (void)trackChannelWithEventObject:(SABaseEventObject *)obj properties:(nullable NSDictionary *)propertyDict NS_EXTENSION_UNAVAILABLE("DeepLink not supported for iOS extensions.") {
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
    NSSet *copyEventNames = [[NSSet alloc] initWithSet:self.trackChannelEventNames copyItems:YES];
    [[SAStoreManager sharedInstance] setObject:copyEventNames forKey:kSAEventPropertyChannelDeviceInfo];
}

- (NSDictionary *)channelInfoWithEvent:(NSString *)event NS_EXTENSION_UNAVAILABLE("DeepLink not supported for iOS extensions.") {
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
        [self showErrorMessage:SALocalizedString(@"SAChannelServerURLError")];
        return NO;
    }
    NSString *project = [SAURLUtils queryItemsWithURLString:url.absoluteString][@"project_name"] ?: @"default";
    BOOL isEqualProject = [network.project isEqualToString:project];
    if (!isEqualProject) {
        [self showErrorMessage:SALocalizedString(@"SAChannelProjectError")];
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
    NSString *deviceId = [queryItems[@"device_code"] stringByRemovingPercentEncoding];

    // 重连二维码对应的设备信息
    NSMutableSet *deviceIdSet = [NSMutableSet setWithArray:[deviceId componentsSeparatedByString:@"##"]];
    // 当前设备的设备信息
    NSSet *installSourceSet = [NSSet setWithArray:[[SACommonUtility appInstallSource] componentsSeparatedByString:@"##"]];
    [deviceIdSet intersectSet:installSourceSet];
    // 取交集，当交集不为空时，表示设备一致
    if (deviceIdSet.count > 0) {
        [self showChannelDebugInstall];
    } else {
        [self showErrorMessage:SALocalizedString(@"SAChannelReconnectError")];
    }
}

#pragma mark - Auth Alert
- (void)showAuthorizationAlertWithURL:(NSURL *)url {
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:SALocalizedString(@"SAChannelEnableJointDebugging") message:nil preferredStyle:SAAlertControllerStyleAlert];
    __weak SAChannelMatchManager *weakSelf = self;
    [alertController addActionWithTitle:SALocalizedString(@"SAAlertOK") style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
        __strong SAChannelMatchManager *strongSelf = weakSelf;
        if ([strongSelf isValidForChannelDebug] && [strongSelf isValidOfDeviceInfo]) {
            NSDictionary *qureyItems = [SAURLUtils queryItemsWithURL:url];
            [strongSelf uploadUserInfoIntoWhiteList:qureyItems];
        } else {
            [strongSelf showChannelDebugErrorMessage];
        }
    }];
    [alertController addActionWithTitle:SALocalizedString(@"SAAlertCancel") style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

- (void)uploadUserInfoIntoWhiteList:(NSDictionary *)qureyItems {
    if (![SAReachability sharedInstance].isReachable) {
        [self showErrorMessage:SALocalizedString(@"SAChannelNetworkError")];
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
    params[@"device_code"] = [SACommonUtility appInstallSource];
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
                    [self showErrorMessage:SALocalizedString(@"SAChannelRequestWhitelistFailed")];
                }
            } else {
                [self showErrorMessage:SALocalizedString(@"SAChannelNetworkException")];
            }
        });
    }];
    [task resume];
}

#pragma mark - ChannelDebugInstall Alert
- (void)showChannelDebugInstall {
    NSString *title = SALocalizedString(@"SAChannelSuccessfullyEnabled");
    NSString *content = SALocalizedString(@"SAChannelTriggerActivation");
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:content preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:SALocalizedString(@"SAChannelActivate") style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
        dispatch_queue_t serialQueue = SensorsAnalyticsSDK.sharedInstance.serialQueue;
        // 入队列前，执行动态公共属性采集 block
        [SensorsAnalyticsSDK.sharedInstance buildDynamicSuperProperties];

        dispatch_async(serialQueue, ^{
            [self trackAppInstall:kSAChannelDebugInstallEventName properties:nil disableCallback:NO];
        });
        [SensorsAnalyticsSDK.sharedInstance flush];

        [self showChannelDebugInstall];
    }];
    [alertController addActionWithTitle:SALocalizedString(@"SAAlertCancel") style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

#pragma mark - Error Message
- (void)showChannelDebugErrorMessage {
    NSString *title = SALocalizedString(@"SAChannelDeviceCodeEmpty");
    NSString *content = SALocalizedString(@"SAChannelTroubleshooting");
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:content preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:SALocalizedString(@"SAAlertOK") style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

- (void)showErrorMessage:(NSString *)errorMessage {
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:SALocalizedString(@"SAAlertHint") message:errorMessage preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:SALocalizedString(@"SAAlertOK") style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

@end
