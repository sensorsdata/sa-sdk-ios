//
// SADeepLinkManager.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/1/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

#import "SADeepLinkManager.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAURLUtils.h"
#import "SAStoreManager.h"
#import "SALog.h"
#import "SAIdentifier.h"
#import "SAJSONUtil.h"
#import "SANetwork.h"
#import "SAModuleManager.h"
#import "SAUserAgent.h"
#import "SensorsAnalyticsSDK+DeepLink.h"
#import "SAApplication.h"
#import "SADeepLinkConstants.h"
#import "SADeepLinkProcessor.h"
#import "SADeferredDeepLinkProcessor.h"
#import "SADeepLinkEventProcessor.h"
#import "SAFirstDayPropertyPlugin.h"
#import "SAPropertyPluginManager.h"
#import "SALatestUtmPropertyPlugin.h"
#import "SADeviceWhiteList.h"
#import "SAAppInteractTracker.h"


@interface SADeepLinkManager () <SADeepLinkProcessorDelegate>

/// 本次唤起时的渠道信息
@property (atomic, strong) NSMutableDictionary *channels;
/// 最后一次唤起时的渠道信息
@property (atomic, copy) NSDictionary *latestChannels;
/// 自定义渠道字段名
@property (nonatomic, copy) NSSet *customChannelKeys;
/// 本次冷启动时的 DeepLinkURL
@property (nonatomic, strong) NSURL *deepLinkURL;

@property (nonatomic, strong) SADeviceWhiteList *whiteList;

@property (nonatomic, strong) SAAppInteractTracker *appInteractTracker;

@property (nonatomic, assign) BOOL hasInstalledApp;

@end

@implementation SADeepLinkManager

typedef NS_ENUM(NSInteger, SADeferredDeepLinkStatus) {
    SADeferredDeepLinkStatusInit = 0,
    SADeferredDeepLinkStatusEnable,
    SADeferredDeepLinkStatusDisable
};

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static SADeepLinkManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SADeepLinkManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //  注册渠道相关属性插件，LatestUtm
        SALatestUtmPropertyPlugin *latestUtmPropertyPlugin = [[SALatestUtmPropertyPlugin alloc] init];
        [SensorsAnalyticsSDK.sharedInstance registerPropertyPlugin:latestUtmPropertyPlugin];

        _channels = [NSMutableDictionary dictionary];
        NSInteger status = [self deferredDeepLinkStatus];

        SAFirstDayPropertyPlugin *firstDayPlugin = [[SAFirstDayPropertyPlugin alloc] init];
        BOOL isFirstDay = [firstDayPlugin isFirstDay];
        // isFirstDay 是为了避免用户版本升级场景下，不需要触发 Deferred DeepLink 逻辑的问题
        if (isFirstDay && status == SADeferredDeepLinkStatusInit) {
            [self enableDeferredDeepLink];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateDidChange:) name:kSAAppLifecycleStateDidChangeNotification object:nil];
        } else {
            [self disableDeferredDeepLink];
        }
        _whiteList = [[SADeviceWhiteList alloc] init];
        _hasInstalledApp = [self isAppInstalled];
    }
    return self;
}

- (void)appLifecycleStateDidChange:(NSNotification *)sender {
    SAAppLifecycleState newState = [sender.userInfo[kSAAppLifecycleNewStateKey] integerValue];
    if (newState == SAAppLifecycleStateEnd) {
        [self disableDeferredDeepLink];
        self.hasInstalledApp = [self isAppInstalled];
    }
}

- (SADeferredDeepLinkStatus)deferredDeepLinkStatus {
    return [[SAStoreManager sharedInstance] integerForKey:kSADeferredDeepLinkStatus];
}

- (void)enableDeferredDeepLink {
    [[SAStoreManager sharedInstance] setInteger:SADeferredDeepLinkStatusEnable forKey:kSADeferredDeepLinkStatus];
}

- (void)disableDeferredDeepLink {
    [[SAStoreManager sharedInstance] setInteger:SADeferredDeepLinkStatusDisable forKey:kSADeferredDeepLinkStatus];
}

- (void)setConfigOptions:(SAConfigOptions *)configOptions NS_EXTENSION_UNAVAILABLE("DeepLink not supported for iOS extensions.") {
    if ([SAApplication isAppExtension]) {
        configOptions.enableDeepLink = NO;
    }
    _configOptions = configOptions;

    [self filterValidSourceChannelKeys:configOptions.sourceChannels];
    [self unarchiveLatestChannels:configOptions.enableSaveDeepLinkInfo];
    [self handleLaunchOptions:configOptions.launchOptions];
    [self acquireColdLaunchDeepLinkInfo];
    self.enable = configOptions.enableDeepLink;
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    self.appInteractTracker = enable && self.configOptions.advertisingConfig.enableRemarketing ? [[SAAppInteractTracker alloc] init] : nil;
    if (!self.appInteractTracker) {
        return;
    }
    NSString *wakeupUrl = self.configOptions.advertisingConfig.wakeupUrl;
    if (!wakeupUrl || ![wakeupUrl isKindOfClass:[NSString class]]) {
        return;
    }
    NSURL *wakeupURL = [NSURL URLWithString:wakeupUrl];
    if (!wakeupURL) {
        return;
    }
    if (![self canHandleURL:wakeupURL]) {
        return;
    }
    self.appInteractTracker.wakeupUrl = wakeupUrl;
}

- (void)filterValidSourceChannelKeys:(NSArray *)sourceChannels {
    NSSet *reservedPropertyName = sensorsdata_reserved_properties();
    NSMutableSet *set = [[NSMutableSet alloc] init];
    // 将用户自定义属性中与 SDK 保留字段相同的字段过滤掉
    for (NSString *name in sourceChannels) {
        if (![reservedPropertyName containsObject:name]) {
            [set addObject:name];
        } else {
            // 这里只做 LOG 提醒
            SALogError(@"deepLink source channel property [%@] is invalid!!!", name);
        }
    }
    self.customChannelKeys = set;
}

- (void)unarchiveLatestChannels:(BOOL)enableSave {
    if (!enableSave) {
        [[SAStoreManager sharedInstance] removeObjectForKey:kSADeepLinkLatestChannelsFileName];
        return;
    }
    NSDictionary *local = [[SAStoreManager sharedInstance] objectForKey:kSADeepLinkLatestChannelsFileName];
    if (!local) {
        return;
    }
    NSArray *array = @[@{@"names":sensorsdata_preset_channel_keys(), @"prefix":@"$latest"},
                       @{@"names":self.customChannelKeys, @"prefix":@"_latest"}];
    NSMutableDictionary *latest = [NSMutableDictionary dictionary];
    for (NSDictionary *obj in array) {
        for (NSString *name in obj[@"names"]) {
            // 升级版本时 sourceChannels 可能会发生变化，过滤掉本次 sourceChannels 中已不包含的字段
            NSString *latestKey = [NSString stringWithFormat:@"%@_%@", obj[@"prefix"], name];
            NSString *value = [local[latestKey] stringByRemovingPercentEncoding];
            if (value.length > 0) {
                latest[latestKey] = value;
            }
        }
    }
    self.latestChannels = latest;
}

/// 开启本地保存 DeepLinkInfo 开关时，每次 DeepLink 唤起解析后都需要更新本地文件中数据
- (void)archiveLatestChannels:(NSDictionary *)dictionary NS_EXTENSION_UNAVAILABLE("DeepLink not supported for iOS extensions.") {
    if (!_configOptions.enableSaveDeepLinkInfo) {
        return;
    }
    [[SAStoreManager sharedInstance] setObject:dictionary forKey:kSADeepLinkLatestChannelsFileName];
}

// 记录冷启动的 DeepLink URL
- (void)handleLaunchOptions:(id)options {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000)
    if (@available(iOS 13.0, *)) {
        // 兼容 SceneDelegate 场景
        if ([options isKindOfClass:UISceneConnectionOptions.class]) {
            UISceneConnectionOptions *sceneOptions = (UISceneConnectionOptions *)options;
            NSUserActivity *userActivity = sceneOptions.userActivities.allObjects.firstObject;
            UIOpenURLContext *urlContext = sceneOptions.URLContexts.allObjects.firstObject;
            _deepLinkURL = urlContext.URL ? urlContext.URL : userActivity.webpageURL;
            return;
        }
    }
#endif
    if (![options isKindOfClass:NSDictionary.class]) {
        return;
    }
    NSDictionary *launchOptions = (NSDictionary *)options;
    if ([launchOptions.allKeys containsObject:UIApplicationLaunchOptionsURLKey]) {
        //通过 SchemeLink 唤起 App
        _deepLinkURL = launchOptions[UIApplicationLaunchOptionsURLKey];
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    else if (@available(iOS 8.0, *)) {
        NSDictionary *userActivityDictionary = launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey];
        NSString *type = userActivityDictionary[UIApplicationLaunchOptionsUserActivityTypeKey];
        if ([type isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            //通过 UniversalLink 唤起 App
            NSUserActivity *userActivity = userActivityDictionary[@"UIApplicationLaunchOptionsUserActivityKey"];
            _deepLinkURL = userActivity.webpageURL;
        }
    }
#endif
}

// 冷启动时 $AppStart 中需要添加 $deeplink_url 信息，且要保证 $AppDeeplinkLaunch 早于 $AppStart。
// 因此这里需要提前处理 DeepLink 逻辑
- (void)acquireColdLaunchDeepLinkInfo {
    // 避免方法被多次调用
    static dispatch_once_t deepLinkToken;
    dispatch_once(&deepLinkToken, ^{
        if (![self canHandleURL:_deepLinkURL]) {
            return;
        }

        [self disableDeferredDeepLink];
        [self handleDeepLinkURL:_deepLinkURL];
    });
}

#pragma mark - channel properties
/// $latest_utm_* 属性，当本次启动是通过 DeepLink 唤起时所有 event 事件都会新增这些属性
- (nullable NSDictionary *)latestUtmProperties {
    return [self.latestChannels copy];
}

/// $utm_* 属性，当通过 DeepLink 唤起 App 时 只针对  $AppStart 事件和第一个 $AppViewScreen 事件会新增这些属性
- (NSDictionary *)utmProperties {
    return [self.channels copy];
}

/// 在固定场景下需要清除 utm_* 属性
// 通过 DeepLink 唤起 App 时需要清除上次的 utm 属性
// 通过 DeepLink 唤起 App 并触发第一个页面浏览时需要清除本次的 utm 属性
// 退出 App 时需要清除本次的 utms 属性
- (void)clearUtmProperties {
    [self.channels removeAllObjects];
}

/// 只有通过 DeepLink 唤起 App 时需要清除 latest utms
- (void)clearLatestUtmProperties {
    self.latestChannels = nil;
}

/// 清空上一次 DeepLink 唤起时的信息，并保存本次唤起的 URL
- (void)clearLastDeepLinkInfo {
    [self clearUtmProperties];
    [self clearLatestUtmProperties];
    // 删除本地保存的 DeepLink 信息
    [self archiveLatestChannels:nil];
}

#pragma mark - Handle DeepLink
- (BOOL)canHandleURL:(NSURL *)url {
    if (![url isKindOfClass:NSURL.class]) {
        return NO;
    }
    if ([self.whiteList canHandleURL:url]) {
        return YES;
    }

    BOOL canWakeUp = [self canWakeUpWithUrl:url];
    self.appInteractTracker.awakeFromDeeplink = canWakeUp;
    return canWakeUp;
}

- (BOOL)canWakeUpWithUrl:(NSURL *)url {
    SADeepLinkProcessor *processor = [SADeepLinkProcessorFactory processorFromURL:url customChannelKeys:self.customChannelKeys];
    return processor.canWakeUp;
}

- (BOOL)handleURL:(NSURL *)url {
    if ([self.whiteList canHandleURL:url]) {
        return [self.whiteList handleURL:url];
    }
    // 当 url 和 _deepLinkURL 相同时，则表示本次触发是冷启动触发,已通过 acquireColdLaunchDeepLinkInfo 方法处理，这里不需要重复处理
    NSString *absoluteString = _deepLinkURL.absoluteString;
    _deepLinkURL = nil;
    if ([url.absoluteString isEqualToString:absoluteString]) {
        return NO;
    }
    return [self handleDeepLinkURL:url];
}

- (BOOL)handleDeepLinkURL:(NSURL *)url {
    if (!url) {
        return NO;
    }

    [self clearLastDeepLinkInfo];

    // 在 channels 中保存本次唤起的 DeepLink URL 添加到指定事件中
    self.channels[kSAEventPropertyDeepLinkURL] = url.absoluteString;

    SADeepLinkProcessor *processor = [SADeepLinkProcessorFactory processorFromURL:url customChannelKeys:self.customChannelKeys];
    processor.delegate = self;
    [processor startWithProperties:@{kSAEventPropertyHasInstalledApp: @(self.hasInstalledApp)}];
    return processor.canWakeUp;
}

#pragma mark - Public Methods
- (void)trackDeepLinkLaunchWithURL:(NSString *)url {
    if (url && ![url isKindOfClass:NSString.class]) {
        SALogError(@"deeplink url must be NSString. got: %@ %@", url.class, url);
        return;
    }
    SADeepLinkEventProcessor *processor = [[SADeepLinkEventProcessor alloc] init];
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    if (self.configOptions.advertisingConfig.enableRemarketing) {
        SAStoreManager *manager = [SAStoreManager sharedInstance];
        BOOL hasInstallApp = [manager boolForKey:kSAHasTrackInstallationDisableCallback] || [manager boolForKey:kSAHasTrackInstallation];
        properties[kSAEventPropertyHasInstalledApp] = @(hasInstallApp);
    }
    properties[kSAEventPropertyDeepLinkURL] = url;
    [processor startWithProperties:properties];
}

- (void)requestDeferredDeepLink:(NSDictionary *)properties {
    // 当不是首次安装 App 时，则不需要再触发 Deferred DeepLink 请求
    if ([self deferredDeepLinkStatus] == SADeferredDeepLinkStatusDisable) {
        return;
    }

    [self disableDeferredDeepLink];

    SADeferredDeepLinkProcessor *processor = [[SADeferredDeepLinkProcessor alloc] init];
    processor.delegate = self;
    processor.customChannelKeys = self.customChannelKeys;
    [processor startWithProperties:properties];
}

#pragma mark - processor delegate
- (SADeepLinkCompletion)sendChannels:(NSDictionary *)channels latestChannels:(NSDictionary *)latestChannels isDeferredDeepLink:(BOOL)isDeferredDeepLink {
    // 合并本次唤起的渠道信息，channels 中已保存 DeepLink URL，所以不能直接覆盖
    [self.channels addEntriesFromDictionary:channels];

    // 覆盖本次唤起的渠道信息，只包含 $latest_utm_* 和 _latest_* 属性
    self.latestChannels = latestChannels;
    [self archiveLatestChannels:latestChannels];

    if (self.completion) {
        return self.completion;
    }

    // 1. 当是 DeferredDeepLink 时，不兼容老版本 completion，不做回调处理
    // 2. 当老版本 completion 也不存在时，不做回调处理
    if (isDeferredDeepLink || !self.oldCompletion) {
        return nil;
    }

    return self.oldCompletion;
}

- (BOOL)isAppInstalled {
    SAStoreManager *manager = [SAStoreManager sharedInstance];
    return [manager boolForKey:kSAHasTrackInstallationDisableCallback] || [manager boolForKey:kSAHasTrackInstallation];
}

@end
