//
// SARemoteConfigCommonOperator.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/7/20.
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

#import "SARemoteConfigCommonOperator.h"
#import "SAReachability.h"
#import "SALog.h"

typedef NS_ENUM(NSInteger, SARemoteConfigHandleRandomTimeType) {
    SARemoteConfigHandleRandomTimeTypeCreate, // 创建分散请求时间
    SARemoteConfigHandleRandomTimeTypeRemove, // 移除分散请求时间
    SARemoteConfigHandleRandomTimeTypeNone    // 不处理分散请求时间
};

static NSString * const kSDKConfigKey = @"SASDKConfig";
static NSString * const kRequestRemoteConfigRandomTimeKey = @"SARequestRemoteConfigRandomTime"; // 保存请求远程配置的随机时间 @{@"randomTime":@double,@"startDeviceTime":@double}
static NSString * const kRandomTimeKey = @"randomTime";
static NSString * const kStartDeviceTimeKey = @"startDeviceTime";

@interface SARemoteConfigCommonOperator ()

@property (nonatomic, assign) NSUInteger requestRemoteConfigRetryMaxCount; // 请求远程配置的最大重试次数

@end

@implementation SARemoteConfigCommonOperator

#pragma mark - Life Cycle

- (instancetype)initWithRemoteConfigOptions:(SARemoteConfigOptions *)options {
    self = [super initWithRemoteConfigOptions:options];
    if (self) {
        _requestRemoteConfigRetryMaxCount = 3;
        [self enableLocalRemoteConfig];
    }
    return self;
}

#pragma mark - Protocol

- (void)enableLocalRemoteConfig {
    NSDictionary *config = [[NSUserDefaults standardUserDefaults] objectForKey:kSDKConfigKey];
    [self enableRemoteConfig:config];
}

- (void)tryToRequestRemoteConfig {
    // 触发远程配置请求的三个条件
    // 1. 判断是否禁用分散请求，如果禁用则直接请求，同时将本地存储的随机时间清除
    if (self.options.configOptions.disableRandomTimeRequestRemoteConfig || self.options.configOptions.maxRequestHourInterval < self.options.configOptions.minRequestHourInterval) {
        [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeRemove isForceUpdate:NO];
        SALogDebug(@"【remote config】Request remote config because disableRandomTimeRequestRemoteConfig or minHourInterval greater than maxHourInterval");
        return;
    }
    
    // 2. 如果开启加密并且未设置公钥（新用户安装或者从未加密版本升级而来），则请求远程配置获取公钥，同时本地生成随机时间
    if (self.options.configOptions.enableEncrypt && !self.options.encryptBuilderCreateResultBlock()) {
        [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeCreate isForceUpdate:NO];
        SALogDebug(@"【remote config】Request remote config because encrypt builder is nil");
        return;
    }
    
    // 获取本地保存的随机时间和设备启动时间
    NSDictionary *requestTimeConfig = [[NSUserDefaults standardUserDefaults] objectForKey:kRequestRemoteConfigRandomTimeKey];
    double randomTime = [[requestTimeConfig objectForKey:kRandomTimeKey] doubleValue];
    double startDeviceTime = [[requestTimeConfig objectForKey:kStartDeviceTimeKey] doubleValue];
    // 获取当前设备启动时间，以开机时间为准，单位：秒
    NSTimeInterval currentTime = NSProcessInfo.processInfo.systemUptime;
    
    // 3. 如果设备重启过或满足分散请求的条件，则强制请求远程配置，同时本地生成随机时间
    if ((currentTime < startDeviceTime) || (currentTime >= randomTime)) {
        [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeCreate isForceUpdate:NO];
        SALogDebug(@"【remote config】Request remote config because the device has been restarted or satisfy the random request condition");
    }
}

- (void)cancelRequestRemoteConfig {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 还未发出请求
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    });
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    [self cancelRequestRemoteConfig];
    [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeCreate isForceUpdate:isForceUpdate];
}

#pragma mark - Private Methods

#pragma mark RandomTime

- (void)handleRandomTimeWithType:(SARemoteConfigHandleRandomTimeType)type {
    switch (type) {
        case SARemoteConfigHandleRandomTimeTypeCreate:
            [self createRandomTime];
            break;
            
        case SARemoteConfigHandleRandomTimeTypeRemove:
            [self removeRandomTime];
            break;
            
        default:
            break;
    }
}

- (void)createRandomTime {
    // 当前时间，以开机时间为准，单位：秒
    NSTimeInterval currentTime = NSProcessInfo.processInfo.systemUptime;
    
    // 计算实际间隔时间（此时只需要考虑 minRequestHourInterval <= maxRequestHourInterval 的情况）
    double realIntervalTime = self.options.configOptions.minRequestHourInterval * 60 * 60;
    if (self.options.configOptions.maxRequestHourInterval > self.options.configOptions.minRequestHourInterval) {
        // 转换成 秒 再取随机时间
        double durationSecond = (self.options.configOptions.maxRequestHourInterval - self.options.configOptions.minRequestHourInterval) * 60 * 60;
        
        // arc4random_uniform 的取值范围，是左闭右开，所以 +1
        realIntervalTime += arc4random_uniform(durationSecond + 1);
    }
    
    // 触发请求后，生成下次随机触发时间
    double randomTime = currentTime + realIntervalTime;
    
    NSDictionary *createRequestTimeConfig = @{kRandomTimeKey: @(randomTime), kStartDeviceTimeKey: @(currentTime) };
    [[NSUserDefaults standardUserDefaults] setObject:createRequestTimeConfig forKey:kRequestRemoteConfigRandomTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeRandomTime {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRequestRemoteConfigRandomTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Request

- (void)requestRemoteConfigWithHandleRandomTimeType:(SARemoteConfigHandleRandomTimeType)type isForceUpdate:(BOOL)isForceUpdate {
    @try {
        [self requestRemoteConfigWithDelay:0 index:0 isForceUpdate:isForceUpdate];
        [self handleRandomTimeWithType:type];
    } @catch (NSException *exception) {
        SALogError(@"【remote config】%@ error: %@", self, exception);
    }
}

- (void)requestRemoteConfigWithDelay:(NSTimeInterval)delay index:(NSUInteger)index isForceUpdate:(BOOL)isForceUpdate {
    __weak typeof(self) weakSelf = self;
    void(^completion)(BOOL success, NSDictionary<NSString *, id> *config) = ^(BOOL success, NSDictionary<NSString *, id> *config) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        @try {
            SALogDebug(@"【remote config】The request result: success is %d, config is %@", success, config);
            
            if (success) {
                if(config != nil) {
                    // 远程配置
                    NSDictionary<NSString *, id> *remoteConfig = [strongSelf extractRemoteConfig:config];
                    [strongSelf handleRemoteConfig:remoteConfig];
                    
                    // 加密
                    if (strongSelf.options.configOptions.enableEncrypt) {
                        NSDictionary<NSString *, id> *encryptConfig = [strongSelf extractEncryptConfig:config];
                        strongSelf.options.handleEncryptBlock(encryptConfig);
                    }
                }
            } else {
                if (index < strongSelf.requestRemoteConfigRetryMaxCount - 1) {
                    [strongSelf requestRemoteConfigWithDelay:30 index:index + 1 isForceUpdate:isForceUpdate];
                }
            }
        } @catch (NSException *e) {
            SALogError(@"【remote config】%@ error: %@", strongSelf, e);
        }
    };
    
    // 子线程不会主动开启 runloop，因此这里切换到主线程执行
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *params = @{@"isForceUpdate" : @(isForceUpdate), @"completion" : completion};
        [self performSelector:@selector(requestRemoteConfigWithParams:) withObject:params afterDelay:delay inModes:@[NSRunLoopCommonModes, NSDefaultRunLoopMode]];
    });
}

- (void)requestRemoteConfigWithParams:(NSDictionary *)params {
    BOOL isForceUpdate = [params[@"isForceUpdate"] boolValue];
    void(^completion)(BOOL success, NSDictionary<NSString *, id> *config) = params[@"completion"];

    if (![SAReachability sharedInstance].isReachable) {
        if (completion) {
            completion(NO, nil);
        }
        return;
    }

    [self requestRemoteConfigWithForceUpdate:isForceUpdate completion:completion];
}

- (void)handleRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig {
    [self updateLocalLibVersion];
    [self trackAppRemoteConfigChanged:remoteConfig];
    [self saveRemoteConfig:remoteConfig];
    [self triggerRemoteConfigEffect:remoteConfig];
}

- (void)updateLocalLibVersion {
    self.model.localLibVersion = self.options.currentLibVersion;
}

- (void)saveRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig {
    [[NSUserDefaults standardUserDefaults] setObject:[self addLibVersionToRemoteConfig:remoteConfig] forKey:kSDKConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)triggerRemoteConfigEffect:(NSDictionary<NSString *, id> *)remoteConfig {
    NSNumber *effectMode = remoteConfig[@"configs"][@"effect_mode"];
    if ([effectMode integerValue] == SARemoteConfigEffectModeNow) {
        [self enableRemoteConfig:[self addLibVersionToRemoteConfig:remoteConfig]];
    }
}

- (NSDictionary<NSString *, id> *)addLibVersionToRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig {
    // 手动添加当前 SDK 版本号
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:remoteConfig];
    result[@"localLibVersion"] = self.options.currentLibVersion;
    return result;
}

@end

