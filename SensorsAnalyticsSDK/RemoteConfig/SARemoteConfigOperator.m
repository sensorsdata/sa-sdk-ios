//
// SARemoteConfigOperator.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/11/1.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SARemoteConfigOperator.h"
#import "SALog.h"
#import "SAURLUtils.h"
#import "SAConstants+Private.h"
#import "SAValidator.h"
#import "SAJSONUtil.h"
#import "SAModuleManager.h"
#import "SARemoteConfigEventObject.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConfigOptions+RemoteConfig.h"

#if __has_include("SAConfigOptions+Encrypt.h")
#import "SAConfigOptions+Encrypt.h"
#endif

@interface SARemoteConfigOperator ()

@property (nonatomic, copy, readonly) NSString *latestVersion;
@property (nonatomic, copy, readonly) NSString *originalVersion;
@property (nonatomic, strong, readonly) NSURL *remoteConfigURL;
@property (nonatomic, strong, readonly) NSURL *serverURL;
@property (nonatomic, assign, readonly) BOOL isDisableDebugMode;
@property (nonatomic, copy, readonly) NSArray<NSString *> *eventBlackList;

@end

@implementation SARemoteConfigOperator

#pragma mark - Life Cycle

- (instancetype)initWithConfigOptions:(SAConfigOptions *)configOptions remoteConfigModel:(SARemoteConfigModel *)model {
    self = [super init];
    if (self) {
        _configOptions = configOptions;
        _model = model;
    }
    return self;
}

#pragma mark - Public

- (BOOL)isBlackListContainsEvent:(nullable NSString *)event {
    if (![SAValidator isValidString:event]) {
        return NO;
    }
    
    return [self.eventBlackList containsObject:event];
}

- (void)requestRemoteConfigWithForceUpdate:(BOOL)isForceUpdate completion:(void (^)(BOOL success, NSDictionary<NSString *, id> * _Nullable config))completion {
    if (!completion) {
        return;
    }

    @try {
        BOOL shouldAddVersion = !isForceUpdate && [self isLibVersionUnchanged] && [self shouldAddVersionOnEnableEncrypt];
        NSString *originalVersion = shouldAddVersion ? self.originalVersion : nil;
        NSString *latestVersion = shouldAddVersion ? self.latestVersion : nil;
        
        NSURLRequest *request = [self buildURLRequestWithOriginalVersion:originalVersion latestVersion:latestVersion];
        if (!request) {
            completion(NO, nil);
            return;
        }
        
        NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
            NSInteger statusCode = response.statusCode;
            BOOL success = statusCode == 200 || statusCode == 304;
            NSDictionary<NSString *, id> *config = nil;
            if (statusCode == 200 && data.length) {
                config = [SAJSONUtil JSONObjectWithData:data];
            }
            
            completion(success, config);
        }];
        [task resume];
    } @catch (NSException *e) {
        SALogError(@"【remote config】%@ error: %@", self, e);
        completion(NO, nil);
    }
}

- (NSDictionary<NSString *, id> *)extractRemoteConfig:(NSDictionary<NSString *, id> *)config {
    @try {
        // 只读取远程配置信息中的开关状态，不处理加密等其他逻辑字段
        NSMutableDictionary<NSString *, id> *configs = [NSMutableDictionary dictionary];
        configs[@"disableDebugMode"] = config[kSARemoteConfigConfigsKey][@"disableDebugMode"];
        configs[@"disableSDK"] = config[kSARemoteConfigConfigsKey][@"disableSDK"];
        configs[@"autoTrackMode"] = config[kSARemoteConfigConfigsKey][@"autoTrackMode"];
        configs[@"event_blacklist"] = config[kSARemoteConfigConfigsKey][@"event_blacklist"];
        configs[@"effect_mode"] = config[kSARemoteConfigConfigsKey][@"effect_mode"];
        configs[@"nv"] = config[kSARemoteConfigConfigsKey][@"nv"];
        configs[kSARemoteConfigSupportTransportEncryptKey] = config[kSARemoteConfigConfigsKey][kSARemoteConfigSupportTransportEncryptKey];

        // 读取远程配置信息中的版本信息
        NSMutableDictionary<NSString *, id> *remoteConfig = [NSMutableDictionary dictionary];
        remoteConfig[@"v"] = config[@"v"];
        remoteConfig[kSARemoteConfigConfigsKey] = configs;

        return remoteConfig;
    } @catch (NSException *exception) {
        SALogError(@"【remote config】%@ error: %@", self, exception);
        return nil;
    }
}

- (void)trackAppRemoteConfigChanged:(NSDictionary<NSString *, id> *)remoteConfig {
    NSString *eventConfigString = [SAJSONUtil stringWithJSONObject:remoteConfig];
    SARemoteConfigEventObject *object = [[SARemoteConfigEventObject alloc] initWithEventId:kSAEventNameAppRemoteConfigChanged];

    [SensorsAnalyticsSDK.sdkInstance trackEventObject:object properties:@{kSAEventPropertyAppRemoteConfig : eventConfigString ?: @""}];
    // 触发 $AppRemoteConfigChanged 时 flush 一次
    [SensorsAnalyticsSDK.sdkInstance flush];
}

- (void)enableRemoteConfig:(NSDictionary *)config {
    self.model = [[SARemoteConfigModel alloc] initWithDictionary:config];
    
    /* 发送远程配置模块 Model 变化通知
     定位和设备方向采集（Location 和 DeviceOrientation 模块），依赖这个通知，如果使用相关功能，必须开启远程控制功能
    */
    [[NSNotificationCenter defaultCenter] postNotificationName:SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:self.model];
}

#pragma mark Network

- (BOOL)isLibVersionUnchanged {
    return [self.model.localLibVersion isEqualToString:SensorsAnalyticsSDK.sdkInstance.libVersion];
}

- (BOOL)shouldAddVersionOnEnableEncrypt NS_EXTENSION_UNAVAILABLE("Encrypt not supported for iOS extensions.") {
#if __has_include("SAConfigOptions+Encrypt.h")
    if (!self.configOptions.enableEncrypt) {
        return YES;
    }
#endif
    return SAModuleManager.sharedInstance.hasSecretKey;
}

- (NSURLRequest *)buildURLRequestWithOriginalVersion:(nullable NSString *)originalVersion latestVersion:(nullable NSString *)latestVersion {
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
            SALogError(@"【remote config】URLString is malformed, nil is returned.");
            return nil;
        }
        urlComponets.query = nil;
        urlComponets.path = [urlComponets.path stringByAppendingPathComponent:@"/config/iOS.conf"];
    }
    
    urlComponets.query = [self buildQueryWithURL:urlComponets.URL originalVersion:originalVersion latestVersion:latestVersion];
    
    return [NSURLRequest requestWithURL:urlComponets.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
}

- (NSString *)buildQueryWithURL:(NSURL *)url originalVersion:(NSString *)originalVersion latestVersion:(NSString *)latestVersion {
    NSDictionary *originalParams = [SAURLUtils queryItemsWithURL:url];
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionaryWithDictionary:originalParams];
    params[@"v"] = originalParams[@"v"] ?: originalVersion;
    params[@"nv"] = originalParams[@"nv"] ?: latestVersion;
    params[@"app_id"] = originalParams[@"app_id"] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    params[@"project"] = originalParams[@"project"] ?: self.project;
    
    return [SAURLUtils urlQueryStringWithParams:params];
}

#pragma mark - Getters and Setters

- (BOOL)isDisableSDK {
    return self.model.disableSDK;
}

- (NSArray<NSString *> *)eventBlackList {
    return self.model.eventBlackList;
}

- (NSString *)latestVersion {
    return self.model.latestVersion;
}

- (NSString *)originalVersion {
    return self.model.originalVersion;
}

- (BOOL)isDisableDebugMode {
    return self.model.disableDebugMode;
}

- (NSURL *)remoteConfigURL NS_EXTENSION_UNAVAILABLE("RemoteConfig not supported for iOS extensions.") {
    return [NSURL URLWithString:self.configOptions.remoteConfigURL];
}

- (NSURL *)serverURL {
    return [NSURL URLWithString:self.configOptions.serverURL];
}

- (NSString *)project {
    return [SAURLUtils queryItemsWithURL:self.serverURL][@"project"];
}

@end
