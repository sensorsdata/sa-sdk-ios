//
// SARemoteConfigManager.m
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

#import "SARemoteConfigManager.h"
#import "SAConstants+Private.h"
#import "SAJSONUtil.h"
#import "SACommonUtility.h"
#import "SALog.h"
#import "SAValidator.h"
#import "SAURLUtils.h"

@implementation SARemoteConfigManagerOptions

@end

typedef NS_ENUM(NSInteger, SARemoteConfigHandleRandomTimeType) {
    SARemoteConfigHandleRandomTimeTypeCreate, // 创建分散请求时间
    SARemoteConfigHandleRandomTimeTypeRemove, // 移除分散请求时间
    SARemoteConfigHandleRandomTimeTypeNone    // 不处理分散请求时间
};

static NSString * const kSDKConfigKey = @"SASDKConfig";
static NSString * const kRequestRemoteConfigRandomTimeKey = @"SARequestRemoteConfigRandomTime"; // 保存请求远程配置的随机时间 @{@"randomTime":@double,@"startDeviceTime":@double}
static NSString * const kRandomTimeKey = @"randomTime";
static NSString * const kStartDeviceTimeKey = @"startDeviceTime";

@interface SARemoteConfigManager ()

@property (atomic, strong) SARemoteConfigModel *remoteConfigModel;
@property (nonatomic, assign) NSUInteger requestRemoteConfigRetryMaxCount; // SDK 开启关闭功能接口最大重试次数
@property (nonatomic, strong) SARemoteConfigManagerOptions *managerOptions;

@property (nonatomic, copy, readonly) NSArray<NSString *> *eventBlackList;
@property (nonatomic, copy, readonly) NSString *latestVersion;
@property (nonatomic, copy, readonly) NSString *originalVersion;
@property (nonatomic, assign, readonly) BOOL isDisableDebugMode;
@property (nonatomic, strong, readonly) NSURL *remoteConfigURL;
@property (nonatomic, strong, readonly) NSURL *serverURL;
@property (nonatomic, copy, readonly) NSString *project;

@end

@implementation SARemoteConfigManager

@synthesize remoteConfigModel = _remoteConfigModel;

#pragma mark - Life Cycle

+ (void)startWithRemoteConfigManagerOptions:(SARemoteConfigManagerOptions *)managerOptions {
    [SARemoteConfigManager sharedInstance].managerOptions = managerOptions;
    [[SARemoteConfigManager sharedInstance] configLocalRemoteConfigModel];
}

+ (instancetype)sharedInstance {
    static SARemoteConfigManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SARemoteConfigManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestRemoteConfigRetryMaxCount = 3;
    }
    return self;
}

#pragma mark - Public Methods

- (void)configLocalRemoteConfigModel {
    NSDictionary *configDic = [[NSUserDefaults standardUserDefaults] objectForKey:kSDKConfigKey];
    self.remoteConfigModel = [[SARemoteConfigModel alloc] initWithDictionary:configDic];
    
    // 发送远程配置模块 Model 变化通知
    [[NSNotificationCenter defaultCenter] postNotificationName:SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:self.remoteConfigModel];
    
    BOOL isDisableSDK = self.isDisableSDK;
    BOOL isDisableDebugMode = self.isDisableDebugMode;
    self.managerOptions.triggerEffectBlock(isDisableSDK, isDisableDebugMode);
}

- (void)requestRemoteConfig {
    // 触发远程配置请求的三个条件
    // 1. 判断是否禁用分散请求，如果禁用则直接请求，同时将本地存储的随机时间清除
    if (self.managerOptions.configOptions.disableRandomTimeRequestRemoteConfig || self.managerOptions.configOptions.maxRequestHourInterval < self.managerOptions.configOptions.minRequestHourInterval) {
        [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeRemove isForceUpdate:NO];
        SALogDebug(@"Request remote config because disableRandomTimerequestRemoteConfig or minHourInterval and maxHourInterval error，Please check the value");
        return;
    }
    
    // 2. 如果开启加密并且未设置公钥（新用户安装或者从未加密版本升级而来），则请求远程配置获取公钥，同时本地生成随机时间
    if (self.managerOptions.configOptions.enableEncrypt && !self.managerOptions.encryptBuilderCreateResultBlock()) {
        [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeCreate isForceUpdate:NO];
        SALogDebug(@"Request remote config because encrypt builder is nil");
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
        SALogDebug(@"Request remote config because the device has been restarted or satisfy the random request condition");
    }
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    [self cancelRequestRemoteConfig];
    [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeCreate isForceUpdate:isForceUpdate];
}

- (void)requestRemoteConfigWithHandleRandomTimeType:(SARemoteConfigHandleRandomTimeType)type isForceUpdate:(BOOL)isForceUpdate {
    @try {
        [self requestRemoteConfigWithDelay:0 index:0 isForceUpdate:isForceUpdate];
        
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
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)cancelRequestRemoteConfig {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 还未发出请求
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    });
}

- (BOOL)isBlackListContainsEvent:(NSString *)event {
    if (![SAValidator isValidString:event]) {
        return NO;
    }
    
    return [self.eventBlackList containsObject:event];
}

#pragma mark - Private Methods

- (BOOL)isLibVersionUnchanged {
    return [self.remoteConfigModel.localLibVersion isEqualToString:self.managerOptions.currentLibVersion];
}

- (BOOL)shouldAddVersionOnEnableEncrypt {
    if (!self.managerOptions.configOptions.enableEncrypt) {
        return YES;
    }
    
    return self.managerOptions.encryptBuilderCreateResultBlock();
}

#pragma mark RandomTime

- (void)createRandomTime {
    // 当前时间，以开机时间为准，单位：秒
    NSTimeInterval currentTime = NSProcessInfo.processInfo.systemUptime;
    
    // 计算实际间隔时间（此时只需要考虑 minRequestHourInterval <= maxRequestHourInterval 的情况）
    double realIntervalTime = self.managerOptions.configOptions.minRequestHourInterval * 60 * 60;
    if (self.managerOptions.configOptions.maxRequestHourInterval > self.managerOptions.configOptions.minRequestHourInterval) {
        // 转换成 秒 再取随机时间
        double durationSecond = (self.managerOptions.configOptions.maxRequestHourInterval - self.managerOptions.configOptions.minRequestHourInterval) * 60 * 60;
        
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

#pragma mark Network

- (void)requestRemoteConfigWithDelay:(NSTimeInterval) delay index:(NSUInteger) index isForceUpdate:(BOOL)isForceUpdate {
    __weak typeof(self) weakSelf = self;
    void(^completion)(BOOL success, NSDictionary<NSString *, id> *config) = ^(BOOL success, NSDictionary<NSString *, id> *config) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        @try {
            SALogDebug(@"The request result of remote config: success is %d, config is %@", success, config);
            
            if (success) {
                if(config != nil) {
                    // 远程配置
                    NSDictionary<NSString *, id> *remoteConfig = [strongSelf extractRemoteConfig:config];
                    [strongSelf handleRemoteConfig:remoteConfig];
                    
                    // 加密
                    if (strongSelf.managerOptions.configOptions.enableEncrypt) {
                        NSDictionary<NSString *, id> *encryptConfig = [strongSelf extractEncryptConfig:config];
                        strongSelf.managerOptions.handleEncryptBlock(encryptConfig);
                    }
                }
            } else {
                if (index < strongSelf.requestRemoteConfigRetryMaxCount - 1) {
                    [strongSelf requestRemoteConfigWithDelay:30 index:index + 1 isForceUpdate:isForceUpdate];
                }
            }
        } @catch (NSException *e) {
            SALogError(@"%@ error: %@", strongSelf, e);
        }
    };
    
    @try {
        // 子线程不会主动开启 runloop，因此这里切换到主线程执行
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *params = @{@"isForceUpdate" : @(isForceUpdate), @"completion" : completion};
            [self performSelector:@selector(requestRemoteConfigWithParams:) withObject:params afterDelay:delay inModes:@[NSRunLoopCommonModes, NSDefaultRunLoopMode]];
        });
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (NSDictionary<NSString *, id> *)extractRemoteConfig:(NSDictionary<NSString *, id> *)config {
    NSMutableDictionary<NSString *, id> *configs = [NSMutableDictionary dictionaryWithDictionary:config[@"configs"]];
    [configs removeObjectForKey:@"key"];
    
    NSMutableDictionary<NSString *, id> *remoteConfig = [NSMutableDictionary dictionaryWithDictionary:config];
    remoteConfig[@"configs"] = configs;
    
    return remoteConfig;
}

- (NSDictionary<NSString *, id> *)extractEncryptConfig:(NSDictionary<NSString *, id> *)config {
    return [config valueForKeyPath:@"configs.key"];
}

- (void)requestRemoteConfigWithParams:(NSDictionary *)params {
    @try {
        BOOL isForceUpdate = [params[@"isForceUpdate"] boolValue];
        void(^completion)(BOOL success, NSDictionary<NSString *, id> *config) = params[@"completion"];
        
        SensorsAnalyticsNetworkType networkType = [SACommonUtility currentNetworkType];
        if (networkType == SensorsAnalyticsNetworkTypeNONE) {
            completion(NO, nil);
            return;
        }
        
        BOOL shouldAddVersion = !isForceUpdate && [self isLibVersionUnchanged] && [self shouldAddVersionOnEnableEncrypt];
        NSString *originalVersion = shouldAddVersion ? self.originalVersion : nil;
        NSString *latestVersion = shouldAddVersion ? self.latestVersion : nil;
        [self functionalManagermentConfigWithOriginalVersion:originalVersion latestVersion:latestVersion completion:completion];
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (nullable NSURLSessionTask *)functionalManagermentConfigWithOriginalVersion:(NSString *)originalVersion
                                                                latestVersion:(NSString *)latestVersion
                                                                   completion:(void(^)(BOOL success, NSDictionary<NSString *, id> *config))completion {
    
    NSURLRequest *request = [self buildFunctionalManagermentConfigRequestWithOriginalVersion:originalVersion latestVersion:latestVersion];
    if (!request) {
        return nil;
    }
    
    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!completion) {
            return ;
        }
        NSInteger statusCode = response.statusCode;
        BOOL success = statusCode == 200 || statusCode == 304;
        NSDictionary<NSString *, id> *config = nil;
        @try{
            if (statusCode == 200 && data.length) {
                config = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            }
        } @catch (NSException *e) {
            SALogError(@"%@ error: %@", self, e);
            success = NO;
        }
        
        // 远程配置的请求回调需要在主线程做一些操作（定位和设备方向等）
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, config);
        });
    }];
    [task resume];
    return task;
}

- (NSURLRequest *)buildFunctionalManagermentConfigRequestWithOriginalVersion:(NSString *)originalVersion
                                                               latestVersion:(NSString *)latestVersion  {
    
    NSURLComponents *urlComponets = nil;
    if (self.remoteConfigURL) {
        urlComponets = [NSURLComponents componentsWithURL:self.remoteConfigURL resolvingAgainstBaseURL:YES];
    }
    if (!urlComponets.host) {
        NSURL *url = self.serverURL.lastPathComponent.length > 0 ? [self.serverURL URLByDeletingLastPathComponent] : self.serverURL;
        if (url) {
            urlComponets = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
        }
        
        if (!urlComponets.host) {
            SALogError(@"URLString is malformed, nil is returned.");
            return nil;
        }
        urlComponets.query = nil;
        urlComponets.path = [urlComponets.path stringByAppendingPathComponent:@"/config/iOS.conf"];
    }

    urlComponets.query = [self buildRemoteConfigQueryWithOriginalVersion:originalVersion latestVersion:latestVersion];
    
    return [NSURLRequest requestWithURL:urlComponets.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
}

- (NSString *)buildRemoteConfigQueryWithOriginalVersion:(NSString *)originalVersion latestVersion:(NSString *)latestVersion {
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionaryWithCapacity:4];
    params[@"v"] = originalVersion;
    params[@"nv"] = latestVersion;
    params[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    params[@"project"] = self.project;
    
    return [SAURLUtils urlQueryStringWithParams:params];
}

- (void)handleRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig {
    [self updateLocalLibVersion];
    [self trackAppRemoteConfigChanged:remoteConfig];
    [self saveRemoteConfig:remoteConfig];
    [self triggerRemoteConfigEffect:remoteConfig];
}

- (void)updateLocalLibVersion {
    self.remoteConfigModel.localLibVersion = self.managerOptions.currentLibVersion;
}

- (void)trackAppRemoteConfigChanged:(NSDictionary<NSString *, id> *)remoteConfig {
    NSString *eventConfigStr = @"";
    NSData *eventConfigData = [SAJSONUtil JSONSerializeObject:remoteConfig];
    if (eventConfigData) {
        eventConfigStr = [[NSString alloc] initWithData:eventConfigData encoding:NSUTF8StringEncoding];
    }
    self.managerOptions.trackEventBlock(SA_EVENT_NAME_APP_REMOTE_CONFIG_CHANGED, @{SA_EVENT_PROPERTY_APP_REMOTE_CONFIG : eventConfigStr});
}

- (void)saveRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig {
    // 手动添加当前 SDK 版本号
    NSMutableDictionary *localRemoteConfig = [NSMutableDictionary dictionaryWithDictionary:remoteConfig];
    localRemoteConfig[@"localLibVersion"] = self.managerOptions.currentLibVersion;
    
    [[NSUserDefaults standardUserDefaults] setObject:localRemoteConfig forKey:kSDKConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)triggerRemoteConfigEffect:(NSDictionary<NSString *, id> *)remoteConfig {
    NSNumber *effectMode = [remoteConfig valueForKeyPath:@"configs.effect_mode"];
    if ([effectMode integerValue] == SARemoteConfigEffectModeNow) {
        [self configLocalRemoteConfigModel];
    }
}

#pragma mark - Getters and Setters

- (BOOL)isDisableSDK {
    return self.remoteConfigModel.disableSDK;
}

- (NSInteger)autoTrackMode {
    return self.remoteConfigModel.autoTrackMode;
}

- (NSArray<NSString *> *)eventBlackList {
    return self.remoteConfigModel.eventBlackList;
}

- (NSString *)latestVersion {
    return self.remoteConfigModel.latestVersion;
}

- (NSString *)originalVersion {
    return self.remoteConfigModel.originalVersion;
}

- (BOOL)isDisableDebugMode {
    return self.remoteConfigModel.disableDebugMode;
}

- (NSURL *)remoteConfigURL {
    return [NSURL URLWithString:self.managerOptions.configOptions.remoteConfigURL];
}

- (NSURL *)serverURL {
    return [NSURL URLWithString:self.managerOptions.configOptions.serverURL];
}

- (NSString *)project {
    return [SAURLUtils queryItemsWithURL:self.serverURL][@"project"];
}

@end

