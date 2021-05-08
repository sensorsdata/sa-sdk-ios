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
#import "SAConfigOptions+Private.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SARSAPluginEncryptor.h"
#import "SAECCPluginEncryptor.h"

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
    }
    return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(nullable NSZone *)zone {
    SAConfigOptions *options = [[[self class] allocWithZone:zone] init];
    options.serverURL = self.serverURL;
    options.launchOptions = self.launchOptions;

    options.autoTrackEventType = self.autoTrackEventType;
    options.enableJavaScriptBridge = self.enableJavaScriptBridge;
    options.enableTrackAppCrash = self.enableTrackAppCrash;
    options.flushInterval = self.flushInterval;
    options.flushBulkSize = self.flushBulkSize;
    options.maxCacheSize = self.maxCacheSize;
    options.enableSaveDeepLinkInfo = self.enableSaveDeepLinkInfo;
    options.sourceChannels = self.sourceChannels;
    options.remoteConfigURL = self.remoteConfigURL;

    options.disableRandomTimeRequestRemoteConfig = self.disableRandomTimeRequestRemoteConfig;
    
    options.minRequestHourInterval = self.minRequestHourInterval;
    options.maxRequestHourInterval = self.maxRequestHourInterval;
    options.enableLog = self.enableLog;
    options.enableHeatMap = self.enableHeatMap;
    options.enableVisualizedAutoTrack = self.enableVisualizedAutoTrack;
    options.enableAutoAddChannelCallbackEvent = self.enableAutoAddChannelCallbackEvent;

    options.flushBeforeEnterBackground = self.flushBeforeEnterBackground;
    options.securityPolicy = [self.securityPolicy copy];
    
    options.enableEncrypt = self.enableEncrypt;
    options.saveSecretKey = self.saveSecretKey;
    options.loadSecretKey = self.loadSecretKey;
    
    options.enableMultipleChannelMatch = self.enableMultipleChannelMatch;

    options.enableReferrerTitle = self.enableReferrerTitle;
    options.enableTrackPush = self.enableTrackPush;

    options.encryptors = self.encryptors;
    
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

- (void)setEnableEncrypt:(BOOL)enableEncrypt {
    _enableEncrypt = enableEncrypt;
    if (enableEncrypt) {
        [self registerEncryptor:[[SAECCPluginEncryptor alloc] init]];
        [self registerEncryptor:[[SARSAPluginEncryptor alloc] init]];
    }
}

- (void)registerEncryptor:(id<SAEncryptProtocol>)encryptor {
    if (![self isValidEncryptor:encryptor]) {
        NSString *format = @"\n 您使用了自定义加密插件 [ %@ ]，但是并没有实现加密协议相关方法。请正确实现自定义加密插件相关功能后再运行项目。\n";
        NSString *message = [NSString stringWithFormat:format, NSStringFromClass(encryptor.class)];
        NSAssert(NO, message);
        return;
    }
    if (!self.encryptors) {
        self.encryptors = [[NSMutableArray alloc] init];
    }
    [self.encryptors addObject:encryptor];
}

- (BOOL)isValidEncryptor:(id<SAEncryptProtocol>)encryptor {
    if (![encryptor respondsToSelector:@selector(symmetricEncryptType)]) {
        return NO;
    }
    if (![encryptor respondsToSelector:@selector(asymmetricEncryptType)]) {
        return NO;
    }
    if (![encryptor respondsToSelector:@selector(encryptEvent:)]) {
        return NO;
    }
    if (![encryptor respondsToSelector:@selector(encryptSymmetricKeyWithPublicKey:)]) {
        return NO;
    }
    return YES;
}

@end

@interface SASecretKey ()

/// 对称加密类型
@property(nonatomic, copy, readwrite) NSString *symmetricEncryptType;

/// 非对称加密类型
@property(nonatomic, copy, readwrite) NSString *asymmetricEncryptType;

@end

@implementation SASecretKey

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.version forKey:@"version"];
    [coder encodeObject:self.key forKey:@"key"];
    [coder encodeObject:self.symmetricEncryptType forKey:@"symmetricEncryptType"];
    [coder encodeObject:self.asymmetricEncryptType forKey:@"asymmetricEncryptType"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.version = [coder decodeIntegerForKey:@"version"];
        self.key = [coder decodeObjectForKey:@"key"];
        self.symmetricEncryptType = [coder decodeObjectForKey:@"symmetricEncryptType"];
        self.asymmetricEncryptType = [coder decodeObjectForKey:@"asymmetricEncryptType"];
    }
    return self;
}

@end

