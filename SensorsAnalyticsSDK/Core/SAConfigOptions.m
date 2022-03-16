//
// SAConfigOptions.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2019/4/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
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

#import "SAConfigOptions.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAIdentifier.h"

@interface SAConfigOptions ()<NSCopying>

@property (atomic, strong, readwrite) NSMutableArray *encryptors;
@property (nonatomic, assign) BOOL enableTrackPush;

@property (nonatomic, assign) BOOL enableHeatMap;
@property (nonatomic, assign) BOOL enableVisualizedAutoTrack;
@property (nonatomic, assign) BOOL enableVisualizedProperties;

@property (nonatomic, assign) BOOL enableTrackAppCrash;

@property (nonatomic, assign) BOOL enableEncrypt;
@property (nonatomic, copy) void (^saveSecretKey)(SASecretKey * _Nonnull secretKey);
@property (nonatomic, copy) SASecretKey * _Nonnull (^loadSecretKey)(void);

@property (nonatomic, assign) BOOL enableSaveDeepLinkInfo;
@property (nonatomic, copy) NSArray<NSString *> *sourceChannels;
@property (nonatomic, assign) BOOL enableAutoAddChannelCallbackEvent;

@property (nonatomic) BOOL enableJavaScriptBridge;

@property (nonatomic, copy) NSString *remoteConfigURL;
@property (nonatomic, assign) BOOL disableRandomTimeRequestRemoteConfig;
@property (nonatomic, assign) NSInteger minRequestHourInterval;
@property (nonatomic, assign) NSInteger maxRequestHourInterval;

@property (nonatomic, assign) BOOL enableTrackPageLeave;
@property (nonatomic, assign) BOOL enableTrackChildPageLeave;
@property (nonatomic) BOOL enableAutoTrackChildViewScreen;
@property (nonatomic) SensorsAnalyticsAutoTrackEventType autoTrackEventType;

//private switch
@property (nonatomic, assign) BOOL enableLocation;
@property (nonatomic, assign) BOOL enableDeviceOrientation;
@property (nonatomic, assign) BOOL enableRemoteConfig;
@property (nonatomic, assign) BOOL enableChannelMatch;
@property (nonatomic, assign) BOOL enableDebugMode;
@property (nonatomic, assign) BOOL enableDeeplink;
@property (nonatomic, assign) BOOL enableAutoTrack;


@end

@implementation SAConfigOptions

#pragma mark - initialize
- (instancetype)initWithServerURL:(NSString *)serverURL launchOptions:(id)launchOptions {
    self = [super init];
    if (self) {
        _serverURL = serverURL;
        _launchOptions = launchOptions;
        _autoTrackEventType = SensorsAnalyticsEventTypeNone;
        
        _flushInterval = 15 * 1000;
        _flushBulkSize = 100;
        _maxCacheSize = 10000;

        _minRequestHourInterval = 24;
        _maxRequestHourInterval = 48;

        _loginIDKey = kSAIdentitiesLoginId;

#ifdef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_CHILD_VIEWSCREEN
        _enableAutoTrackChildViewScreen = YES;
#endif

        _flushNetworkPolicy =
#if TARGET_OS_IOS
        SensorsAnalyticsNetworkType3G |
        SensorsAnalyticsNetworkType4G |
#ifdef __IPHONE_14_1
        SensorsAnalyticsNetworkType5G |
#endif
#endif
        SensorsAnalyticsNetworkTypeWIFI;

        //default private switch
        _enableRemoteConfig = YES;
        _enableChannelMatch = YES;
        _enableDebugMode = YES;
        _enableDeeplink = YES;
        _enableAutoTrack = YES;

        _storePlugins = [NSMutableArray array];
        _ignoredPageLeaveClasses = [NSSet set];
    }
    return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(nullable NSZone *)zone {
    SAConfigOptions *options = [[[self class] allocWithZone:zone] init];
    options.serverURL = self.serverURL;
    options.launchOptions = self.launchOptions;
    options.enableJavaScriptBridge = self.enableJavaScriptBridge;
    options.flushInterval = self.flushInterval;
    options.flushBulkSize = self.flushBulkSize;
    options.maxCacheSize = self.maxCacheSize;
    options.enableLog = self.enableLog;
    options.flushBeforeEnterBackground = self.flushBeforeEnterBackground;
    options.flushNetworkPolicy = self.flushNetworkPolicy;
    options.disableSDK = self.disableSDK;
    options.storePlugins = self.storePlugins;
    options.loginIDKey = self.loginIDKey;
    options.enableSession = self.enableSession;
    options.disableDeviceId = self.disableDeviceId;

#if TARGET_OS_IOS
    // 支持 https 自签证书
    options.securityPolicy = [self.securityPolicy copy];

    // 远程控制
    options.minRequestHourInterval = self.minRequestHourInterval;
    options.maxRequestHourInterval = self.maxRequestHourInterval;
    options.remoteConfigURL = self.remoteConfigURL;
    options.disableRandomTimeRequestRemoteConfig = self.disableRandomTimeRequestRemoteConfig;
    // 加密
    options.encryptors = self.encryptors;
    options.enableEncrypt = self.enableEncrypt;
    options.saveSecretKey = self.saveSecretKey;
    options.loadSecretKey = self.loadSecretKey;
    // 全埋点
    options.autoTrackEventType = self.autoTrackEventType;
    options.enableAutoTrackChildViewScreen = self.enableAutoTrackChildViewScreen;
    options.enableHeatMap = self.enableHeatMap;
    options.enableVisualizedAutoTrack = self.enableVisualizedAutoTrack;
    options.enableVisualizedProperties = self.enableVisualizedProperties;

    // Crash 采集
    options.enableTrackAppCrash = self.enableTrackAppCrash;
    // 渠道相关
    options.enableSaveDeepLinkInfo = self.enableSaveDeepLinkInfo;
    options.sourceChannels = self.sourceChannels;
    options.enableAutoAddChannelCallbackEvent = self.enableAutoAddChannelCallbackEvent;
    // 推送点击
    options.enableTrackPush = self.enableTrackPush;
    // 页面浏览时长
    options.enableTrackPageLeave = self.enableTrackPageLeave;
    options.enableTrackChildPageLeave = self.enableTrackChildPageLeave;
    options.ignoredPageLeaveClasses = self.ignoredPageLeaveClasses;

    //private switch
    options.enableRemoteConfig = self.enableRemoteConfig;
    options.enableChannelMatch = self.enableChannelMatch;
    options.enableDebugMode = self.enableDebugMode;
    options.enableDeeplink = self.enableDeeplink;
    options.enableAutoTrack = self.enableAutoTrack;
#endif
    
    return options;
}

#pragma mark set
- (void)setFlushInterval:(NSInteger)flushInterval {
    _flushInterval = flushInterval >= 5000 ? flushInterval : 5000;
}

- (void)setFlushBulkSize:(NSInteger)flushBulkSize {
    _flushBulkSize = flushBulkSize >= 50 ? flushBulkSize : 50;
}

- (void)setMaxCacheSize:(NSInteger)maxCacheSize {
    //防止设置的值太小导致事件丢失
    _maxCacheSize = maxCacheSize >= 10000 ? maxCacheSize : 10000;
}

- (void)setMinRequestHourInterval:(NSInteger)minRequestHourInterval {
    if (minRequestHourInterval > 0) {
        _minRequestHourInterval = MIN(minRequestHourInterval, 7*24);
    }
}

- (void)setMaxRequestHourInterval:(NSInteger)maxRequestHourInterval {
    if (maxRequestHourInterval > 0) {
        _maxRequestHourInterval = MIN(maxRequestHourInterval, 7*24);
    }
}

- (void)registerStorePlugin:(id<SAStorePlugin>)plugin {
    [self.storePlugins addObject:plugin];
}

- (void)ignorePageLeave:(NSArray<Class> *)viewControllers {
    if (![viewControllers isKindOfClass:[NSArray class]]) {
        return;
    }
    self.ignoredPageLeaveClasses = [NSSet setWithArray:viewControllers];
}

@end



