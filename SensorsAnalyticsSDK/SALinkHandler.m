//
// SALinkHandler.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/1/6.
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

#import "SALinkHandler.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAURLUtils.h"
#import "SAFileStore.h"
#import "SALog.h"

static NSString *const SAAppDeeplinkLaunchEvent = @"$AppDeeplinkLaunch";
static NSString *const SADeeplinkMatchedResultEvent = @"$AppDeeplinkMatchedResult";

@interface SALinkHandler ()

/// 包含 SDK 预置属性和用户自定义属性
@property (nonatomic, strong) NSMutableDictionary *utms;
@property (nonatomic, copy) NSDictionary *latestUtms;
/// 预置属性列表
@property (nonatomic, copy) NSSet *presetUtms;
/// 过滤后的用户自定义属性
@property (nonatomic, copy) NSSet *sourceChannels;
/// SDK初始化时的 ConfigOptions
@property (nonatomic, copy) SAConfigOptions *configOptions;

@property (nonatomic, strong) NSURL *deeplinkURL;

@end

static NSString *const kSavedDeepLinkInfoFileName = @"latest_utms";

@implementation SALinkHandler

- (instancetype)initWithConfigOptions:(SAConfigOptions *)configOptions {
    self = [super init];
    if (self) {
        _configOptions = [configOptions copy];
        // 设置需要解析的预置属性名
        _presetUtms = [NSSet setWithObjects:@"utm_campaign", @"utm_content", @"utm_medium", @"utm_source", @"utm_term", nil];
        _utms = [NSMutableDictionary dictionary];

        [self filterInvalidSourceChannnels];
        [self unarchiveSavedDeepLinkInfo];
        [self handleLaunchOptions:configOptions.launchOptions];
    }
    return self;
}

- (void)filterInvalidSourceChannnels {
    NSSet *reservedPropertyName = sensorsdata_reserved_properties();
    NSMutableSet *set = [[NSMutableSet alloc] init];
    // 将用户自定义属性中与 SDK 保留字段相同的字段过滤掉
    for (NSString *name in _configOptions.sourceChannels) {
        if (![reservedPropertyName containsObject:name]) {
            [set addObject:name];
        } else {
            // 这里只做 LOG 提醒
            SALogError(@"deeplink source channel property [%@] is invalid!!!", name);
        }
    }
    _sourceChannels = set;
}

- (void)unarchiveSavedDeepLinkInfo {
    if (!_configOptions.enableSaveDeepLinkInfo) {
        [SAFileStore archiveWithFileName:kSavedDeepLinkInfoFileName value:nil];
        return;
    }
    NSDictionary *local = [SAFileStore unarchiveWithFileName:kSavedDeepLinkInfoFileName];
    if (!local) {
        return;
    }
    NSMutableDictionary *latest = [NSMutableDictionary dictionary];
    for (NSString *name in _presetUtms) {
        NSString *newName = [NSString stringWithFormat:@"$latest_%@", name];
        if (local[newName]) {
            latest[newName] = local[newName];
        }
    }
    // 升级版本时 sourceChannels 可能会发生变化，过滤掉本次 sourceChannels 中已不包含的字段
    for (NSString *name in _sourceChannels) {
        NSString *newName = [NSString stringWithFormat:@"_latest_%@", name];
        if (local[newName]) {
            latest[newName] = local[newName];
        }
    }
    _latestUtms = latest;
}

#pragma mark - utm properties
/// $latest_utm_* 属性，当本次启动是通过 DeepLink 唤起时所有 event 事件都会新增这些属性
- (nullable NSDictionary *)latestUtmProperties {
    return [_latestUtms copy];
}

/// $utm_* 属性，当通过 DeepLink 唤起 App 时 只针对  $AppStart 事件和第一个 $AppViewScreen 事件会新增这些属性
- (NSDictionary *)utmProperties {
    return [_utms copy];
}

/// 在固定场景下需要清除 utm_* 属性
// 通过 DeepLink 唤起 App 时需要清除上次的 utm 属性
// 通过 DeepLink 唤起 App 并触发第一个页面浏览时需要清除本次的 utm 属性
// 退出 App 时需要清除本次的 utms 属性
- (void)clearUtmProperties {
    [_utms removeAllObjects];
}

/// 只有通过 DeepLink 唤起 App 时需要清除 latest utms
- (void)clearLatestUtmProperties {
    _latestUtms = nil;
}

/// 清空上一次 DeepLink 唤起时的信息，并保存本次唤起的 URL
- (void)clearLastDeepLinkInfo:(NSURL *)url {
    [self clearUtmProperties];
    [self clearLatestUtmProperties];
    // 删除本地保存的 DeepLink 信息
    [self saveDeepLinkInfo:nil];
    _utms[@"$deeplink_url"] = url.absoluteString;
}

#pragma mark - save latest utms in local file
/// 开启本地保存 DeepLinkInfo 开关时，每次 DeepLink 唤起解析后都需要更新本地文件中数据
- (void)saveDeepLinkInfo:(NSDictionary *)dictionary {
    if (!_configOptions.enableSaveDeepLinkInfo) {
        return;
    }
    [SAFileStore archiveWithFileName:kSavedDeepLinkInfoFileName value:dictionary];
}

#pragma mark - parse utms
- (BOOL)canHandleURL:(NSURL *)url {
    if (![url isKindOfClass:NSURL.class]) {
        return NO;
    }
    return [self isValidURLForLocalMode:url] || [self isValidURLForServerMode:url];
}

// URL 的 Query 中包含一个或多个 utm_* 参数。示例：https://sensorsdata.cn?utm_content=1&utm_campaign=2
// utm_* 参数共五个，"utm_campaign", "utm_content", "utm_medium", "utm_source", "utm_term"
- (BOOL)isValidURLForLocalMode:(NSURL *)url {
    NSDictionary *queryItems = [SAURLUtils queryItemsWithURL:url];
    for (NSString *key in _presetUtms) {
        if (queryItems[key]) {
            return YES;
        }
    }
    for (NSString *key in _sourceChannels) {
        if (queryItems[key]) {
            return YES;
        }
    }
    return NO;
}

// 记录冷启动的 DeepLink URL
- (void)handleLaunchOptions:(NSDictionary *)launchOptions {
    if (![launchOptions isKindOfClass:NSDictionary.class]) {
        return;
    }
    NSURL *url;
    if ([launchOptions.allKeys containsObject:UIApplicationLaunchOptionsURLKey]) {
        //通过 SchemeLink 唤起 App
        url = launchOptions[UIApplicationLaunchOptionsURLKey];
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    else if (@available(iOS 8.0, *)) {
        NSDictionary *userActivityDictionary = launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey];
        NSString *type = userActivityDictionary[UIApplicationLaunchOptionsUserActivityTypeKey];
        if ([type isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            //通过 UniversalLink 唤起 App
            NSUserActivity *userActivity = userActivityDictionary[@"UIApplicationLaunchOptionsUserActivityKey"];
            url = userActivity.webpageURL;
        }
    }
#endif
    _deeplinkURL = url;
}

/// 获取冷启动时的 DeepLink 信息，并触发 Launch 事件
- (void)acquireColdLaunchDeepLinkInfo {
    // 避免方法被多次调用
    static dispatch_once_t deepLinkToken;
    dispatch_once(&deepLinkToken, ^{
        if (![self canHandleURL:_deeplinkURL]) {
            return;
        }
        [self checkDeepLinkMode:_deeplinkURL];
    });
}

- (void)handleDeepLink:(NSURL *)url {
    // 当 url 和 _deepLinkURL 相同时，则表示本次触发是冷启动触发,已通过 acquireColdLaunchDeepLinkInfo 方法处理，这里不需要重复处理
    NSString *absoluteString = _deeplinkURL.absoluteString;
    _deeplinkURL = nil;
    if ([url.absoluteString isEqualToString:absoluteString]) {
        return;
    }
    [self checkDeepLinkMode:url];
}

- (void)checkDeepLinkMode:(NSURL *)url {
    if (![url isKindOfClass:NSURL.class]) {
        return;
    }
    [self clearLastDeepLinkInfo:url];

    if ([self isValidURLForServerMode:url]) {
        // ServerMode 先触发 Launch 事件再请求接口，Launch 事件中只新增 $deeplink_url 属性
        [self trackAppDeepLinkLaunchEvent:url];
        [self requestDeepLinkInfo:url];
    } else {
        // LocalMode 先解析 Query 参数后再触发 Launch 事件，Launch 事件中有 utm_* 属性信息
        NSDictionary *dictionary = [SAURLUtils queryItemsWithURL:url];
        [self acquireCurrentDeepLinkInfo:dictionary];
        [self trackAppDeepLinkLaunchEvent:url];
    }
}

/// 通过 URL 的 Query 获取本次的 utm_* 属性
- (void)acquireCurrentDeepLinkInfo:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:NSDictionary.class]) {
        return;
    }
    _utms = [self acquireUtmProperties:dictionary];
    _latestUtms = [self acquireLatestUtmProperties:dictionary];
}

- (NSMutableDictionary *)acquireUtmProperties:(NSDictionary *)dictionary {
    NSMutableDictionary *utmProperties = [NSMutableDictionary dictionary];
        for (NSString *propKey in _presetUtms) {
        NSString *propValue = [dictionary[propKey] stringByRemovingPercentEncoding];
        if (propValue.length > 0) {
            NSString *utmKey = [NSString stringWithFormat:@"$%@", propKey];
            utmProperties[utmKey] = propValue;
        }
    }
    for (NSString *propKey in _sourceChannels) {
        NSString *propValue = [dictionary[propKey] stringByRemovingPercentEncoding];
        if (propValue.length > 0) {
            utmProperties[propKey] = propValue;
        }
    }
    return utmProperties;
}

- (NSDictionary *)acquireLatestUtmProperties:(NSDictionary *)dictionary {
    __block NSMutableDictionary *latest = [NSMutableDictionary dictionary];
    void(^block)(NSString *propKey, NSString *keyPrefix) = ^(NSString *propKey, NSString *keyPrefix) {
        NSString *propValue = [dictionary[propKey] stringByRemovingPercentEncoding];
        if (propValue.length > 0) {
            NSString *latestKey = [NSString stringWithFormat:@"%@_%@", keyPrefix, propKey];
            latest[latestKey] = propValue;
        }
    };
    //SDK 预置属性，示例：$latest_utm_content。
    for (NSString *propKey in _presetUtms) {
        block(propKey, @"$latest");
    }
    // 用户自定义的属性，不是 SDK 的预置属性，因此以 _latest 开头，避免 SA 平台报错。示例：_lateset_customKey
    for (NSString *propKey in _sourceChannels) {
        block(propKey, @"_latest");
    }
    [self saveDeepLinkInfo:latest];
    return latest;
}

#pragma mark - Server Mode
/// URL 的 Path 符合特定规则。示例：https://{域名}/sd/{appId}/{key} 或 {scheme}://sensorsdata/sd/{key}
- (BOOL)isValidURLForServerMode:(NSURL *)url {
    NSArray *pathComponents = url.pathComponents;
    if (pathComponents.count < 2 || ![pathComponents[1] isEqualToString:@"sd"]) {
        return NO;
    }
    NSString *host = SensorsAnalyticsSDK.sharedInstance.network.serverURL.host;
    return ([url.host isEqualToString:@"sensorsdata"] || [url.host isEqualToString:host]);
}

- (NSURLRequest *)buildRequestWithURL:(NSURL *)url {
    NSURL *serverURL = SensorsAnalyticsSDK.sharedInstance.network.serverURL;
    if (serverURL.absoluteString.length <= 0) {
        return nil;
    }
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = serverURL.scheme;
    components.host = serverURL.host;
    components.path = @"/sdk/deeplink/param";
    NSString *key = url.lastPathComponent;
    NSString *project = SensorsAnalyticsSDK.sharedInstance.network.project;
    components.query = [NSString stringWithFormat:@"key=%@&project=%@&system_type=IOS", key, project];
    NSURL *URL = [components URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.timeoutInterval = 60;
    [request setHTTPMethod:@"GET"];
    return request;
}

- (void)requestDeepLinkInfo:(NSURL *)url {
    NSURLRequest *request = [self buildRequestWithURL:url];
    if (!request) {
        return;
    }
    NSTimeInterval start = NSDate.date.timeIntervalSince1970;
    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        NSTimeInterval interval = (NSDate.date.timeIntervalSince1970 - start);
        NSDictionary *result;
        NSString *errorMsg;
        BOOL success  = NO;
        if (response.statusCode == 200 && data) {
            result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            errorMsg = result[@"errorMsg"];
            success = errorMsg.length <= 0;
            self.latestUtms = [self acquireLatestUtmProperties:result[@"channel_params"]];
        } else {
            NSString *codeMsg = [NSString stringWithFormat:@"http status code: %@",@(response.statusCode)];
            errorMsg = error.localizedDescription ?: codeMsg;
        }
        [self trackDeeplinkMatchedResult:url result:result interval:interval errorMsg:errorMsg];
        if (self.linkHandlerCallback) {
            self.linkHandlerCallback(result[@"page_params"], success, interval * 1000);
        }
    }];
    [task resume];
}

#pragma mark - deeplink event
- (void)trackAppDeepLinkLaunchEvent:(NSURL *)url {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    [props addEntriesFromDictionary:_utms];
    [props addEntriesFromDictionary:_latestUtms];
    props[@"$deeplink_url"] = url.absoluteString;
    [[SensorsAnalyticsSDK sharedInstance] track:SAAppDeeplinkLaunchEvent withProperties:props];
}

- (void)trackDeeplinkMatchedResult:(NSURL *)url result:(NSDictionary *)result interval:(NSTimeInterval)interval errorMsg:(NSString *)errorMsg {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    props[@"$event_duration"] = [NSString stringWithFormat:@"%.3f", interval];
    props[@"$deeplink_options"] = result[@"page_params"];
    props[@"$deeplink_match_fail_reason"] = errorMsg.length ? errorMsg : nil;
    props[@"$deeplink_url"] = url.absoluteString;
    NSDictionary *utms = [self acquireUtmProperties:result[@"channel_params"]];
    [props addEntriesFromDictionary:utms];
    [[SensorsAnalyticsSDK sharedInstance] track:SADeeplinkMatchedResultEvent withProperties:props];
}

@end
