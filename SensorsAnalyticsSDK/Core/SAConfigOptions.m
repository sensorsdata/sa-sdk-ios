//
//  SAConfigOptions.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2019/4/8.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAConfigOptions.h"
#import "SensorsAnalyticsSDK+Private.h"

@interface SAConfigOptions ()<NSCopying>

@property (nonatomic, strong, readwrite) NSMutableArray *encryptors;

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

        _flushBeforeEnterBackground = YES;

#ifdef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_CHILD_VIEWSCREEN
        _enableAutoTrackChildViewScreen = YES;
#endif
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
    options.enableReferrerTitle = self.enableReferrerTitle;
    options.enableHeatMap = self.enableHeatMap;
    options.enableVisualizedAutoTrack = self.enableVisualizedAutoTrack;
    // Crash 采集
    options.enableTrackAppCrash = self.enableTrackAppCrash;
    // 渠道相关
    options.enableSaveDeepLinkInfo = self.enableSaveDeepLinkInfo;
    options.sourceChannels = self.sourceChannels;
    options.enableMultipleChannelMatch = self.enableMultipleChannelMatch;
    options.enableAutoAddChannelCallbackEvent = self.enableAutoAddChannelCallbackEvent;
    // 推送点击
    options.enableTrackPush = self.enableTrackPush;
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

@end



