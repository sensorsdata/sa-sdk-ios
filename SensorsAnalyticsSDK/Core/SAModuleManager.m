//
// SAModuleManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/8/14.
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

#import "SAModuleManager.h"
#import "SAModuleProtocol.h"
#import "SAConfigOptions.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAThreadSafeDictionary.h"

// Location 模块名
static NSString * const kSALocationModuleName = @"Location";
static NSString * const kSADeviceOrientationModuleName = @"DeviceOrientation";
static NSString * const kSADebugModeModuleName = @"DebugMode";
static NSString * const kSAChannelMatchModuleName = @"ChannelMatch";
/// 可视化相关（可视化全埋点和点击图）
static NSString * const kSAVisualizedModuleName = @"Visualized";

static NSString * const kSAEncryptModuleName = @"Encrypt";
static NSString * const kSADeeplinkModuleName = @"Deeplink";
static NSString * const kSANotificationModuleName = @"AppPush";
static NSString * const kSAAutoTrackModuleName = @"AutoTrack";
static NSString * const kSARemoteConfigModuleName = @"RemoteConfig";

static NSString * const kSAJavaScriptBridgeModuleName = @"JavaScriptBridge";
static NSString * const kSAExceptionModuleName = @"Exception";

@interface SAModuleManager ()

/// 已开启的模块
@property (nonatomic, strong) NSArray<NSString *> *moduleNames;

@property (nonatomic, strong) SAConfigOptions *configOptions;

@end

@implementation SAModuleManager

+ (void)startWithConfigOptions:(SAConfigOptions *)configOptions {
    SAModuleManager.sharedInstance.configOptions = configOptions;
    // 禁止 SDK 时，不开启其他模块
    if (configOptions.disableSDK) {
        return;
    }
    [[SAModuleManager sharedInstance] loadModulesWithConfigOptions:configOptions];
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAModuleManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAModuleManager alloc] init];
    });
    return manager;
}

#pragma mark - Private
- (NSString *)classNameForModule:(NSString *)moduleName {
    return [NSString stringWithFormat:@"SA%@Manager", moduleName];
}

- (id)moduleWithName:(NSString *)moduleName {
    NSString *className = [self classNameForModule: moduleName];
    Class moduleClass = NSClassFromString(className);
    if (!moduleClass) {
        return nil;
    }
    SEL sharedManagerSEL = NSSelectorFromString(@"defaultManager");
    if (![moduleClass respondsToSelector:sharedManagerSEL]) {
        return nil;
    }
    id (*sharedManager)(id, SEL) = (id (*)(id, SEL))[moduleClass methodForSelector:sharedManagerSEL];

    id module = sharedManager(moduleClass, sharedManagerSEL);
    return module;
}

// module加载
- (void)loadModulesWithConfigOptions:(SAConfigOptions *)configOptions {
    [self loadModule:kSAJavaScriptBridgeModuleName withConfigOptions:configOptions];
#if TARGET_OS_IOS
    for (NSString *moduleName in self.moduleNames) {
        if ([moduleName isEqualToString:kSAJavaScriptBridgeModuleName]) {
            continue;
        }
        [self loadModule:moduleName withConfigOptions:configOptions];
    }
#endif
}

- (void)loadModule:(NSString *)moduleName withConfigOptions:(SAConfigOptions *)configOptions {
    if (!moduleName) {
        return;
    }
    id module = [self moduleWithName:moduleName];
    if (!module) {
        return;
    }
    if ([module conformsToProtocol:@protocol(SAModuleProtocol)] && [module respondsToSelector:@selector(setConfigOptions:)]) {
        id<SAModuleProtocol>moduleObject = (id<SAModuleProtocol>)module;
        moduleObject.configOptions = configOptions;
    }
}

- (NSArray<NSString *> *)moduleNames {
    return @[kSAJavaScriptBridgeModuleName, kSANotificationModuleName, kSAChannelMatchModuleName,
             kSADeeplinkModuleName, kSADebugModeModuleName, kSALocationModuleName,
             kSAAutoTrackModuleName, kSAVisualizedModuleName, kSAEncryptModuleName,
             kSADeviceOrientationModuleName, kSAExceptionModuleName, kSARemoteConfigModuleName];
}

#pragma mark - Public

- (BOOL)isDisableSDK {
    if (self.configOptions.disableSDK) {
        return YES;
    }
    id module = [self moduleWithName:kSARemoteConfigModuleName];
    if ([module conformsToProtocol:@protocol(SARemoteConfigModuleProtocol)] && [module conformsToProtocol:@protocol(SAModuleProtocol)]) {
        id<SARemoteConfigModuleProtocol, SAModuleProtocol> manager = module;
        return manager.isEnable ? manager.isDisableSDK : NO;
    }
    return NO;
}

- (void)disableAllModules {
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            continue;
        }
        if ([module conformsToProtocol:@protocol(SAModuleProtocol)] && [module respondsToSelector:@selector(setEnable:)]) {
            id<SAModuleProtocol>moduleObject = module;
            moduleObject.enable = NO;
        }
    }
}

- (void)updateServerURL:(NSString *)serverURL {
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            continue;
        }
        if ([module conformsToProtocol:@protocol(SAModuleProtocol)] && [module respondsToSelector:@selector(isEnable)] && [module respondsToSelector:@selector(updateServerURL:)]) {
            id<SAModuleProtocol>moduleObject = module;
            moduleObject.isEnable ? [module updateServerURL:serverURL] : nil;
        }
    }
}

#pragma mark - Open URL

- (BOOL)canHandleURL:(NSURL *)url {
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            continue;
        }
        if (![module conformsToProtocol:@protocol(SAOpenURLProtocol)]) {
            continue;
        }
        if (![module respondsToSelector:@selector(canHandleURL:)]) {
            continue;
        }
        id<SAOpenURLProtocol>moduleObject = module;
        if ([moduleObject canHandleURL:url]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)handleURL:(NSURL *)url {
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            continue;
        }
        if (![module conformsToProtocol:@protocol(SAOpenURLProtocol)]) {
            continue;
        }
        if (![module respondsToSelector:@selector(canHandleURL:)] || ![module respondsToSelector:@selector(handleURL:)]) {
            continue;
        }
        id<SAOpenURLProtocol>moduleObject = module;
        if ([moduleObject canHandleURL:url]) {
            return [moduleObject handleURL:url];
        }
    }
    return NO;
}

@end

#pragma mark -

@implementation SAModuleManager (Property)

- (NSDictionary *)properties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 兼容使用宏定义的方式源码集成 SDK
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            continue;
        }
        if (![module conformsToProtocol:@protocol(SAPropertyModuleProtocol)] || ![module conformsToProtocol:@protocol(SAModuleProtocol)]) {
            continue;
        }
        if (![module respondsToSelector:@selector(properties)] && [module respondsToSelector:@selector(isEnable)]) {
            continue;
        }
        id<SAPropertyModuleProtocol, SAModuleProtocol>moduleObject = module;
        if (!moduleObject.isEnable) {
            continue;
        }
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
        if ([moduleName isEqualToString:kSALocationModuleName]) {
            [properties addEntriesFromDictionary:moduleObject.properties];
            continue;
        }
#endif
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
        if ([moduleName isEqualToString:kSADeviceOrientationModuleName]) {
            [properties addEntriesFromDictionary:moduleObject.properties];
            continue;
        }
#endif
        if (moduleObject.properties.count > 0) {
            [properties addEntriesFromDictionary:moduleObject.properties];
        }
    }
    return properties;
}

@end

#pragma mark -

@implementation SAModuleManager (ChannelMatch)

- (id<SAChannelMatchModuleProtocol>)channelMatchManager {
    id module = [self moduleWithName:kSAChannelMatchModuleName];
    if ([module conformsToProtocol:@protocol(SAChannelMatchModuleProtocol)] && [module conformsToProtocol:@protocol(SAModuleProtocol)]) {
        id<SAChannelMatchModuleProtocol, SAModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (void)trackAppInstall:(NSString *)event properties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback {
    [self.channelMatchManager trackAppInstall:event properties:properties disableCallback:disableCallback];
}

- (void)trackChannelWithEventObject:(SABaseEventObject *)obj properties:(NSDictionary *)properties {
    [self.channelMatchManager trackChannelWithEventObject:obj properties:properties];
}

- (NSDictionary *)channelInfoWithEvent:(NSString *)event {
    return [self.channelMatchManager channelInfoWithEvent:event];
}

@end

#pragma mark -

@implementation SAModuleManager (DebugMode)

- (id<SADebugModeModuleProtocol>)debugModeManager {
    id module = [self moduleWithName:kSADebugModeModuleName];
    if ([module conformsToProtocol:@protocol(SADebugModeModuleProtocol)] && [module conformsToProtocol:@protocol(SAModuleProtocol)]) {
        id<SADebugModeModuleProtocol, SAModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (void)setDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    self.debugModeManager.debugMode = debugMode;
}

- (SensorsAnalyticsDebugMode)debugMode {
    return self.debugModeManager.debugMode;
}

- (void)setShowDebugAlertView:(BOOL)isShow {
    [self.debugModeManager setShowDebugAlertView:isShow];
}

- (void)handleDebugMode:(SensorsAnalyticsDebugMode)mode {
    [self.debugModeManager handleDebugMode:mode];
}

- (void)showDebugModeWarning:(NSString *)message {
    [self.debugModeManager showDebugModeWarning:message];
}

@end

#pragma mark -
@implementation SAModuleManager (Encrypt)

- (id<SAEncryptModuleProtocol>)encryptManager {
    id module = [self moduleWithName:kSAEncryptModuleName];
    if ([module conformsToProtocol:@protocol(SAEncryptModuleProtocol)] && [module conformsToProtocol:@protocol(SAModuleProtocol)]) {
        id<SAEncryptModuleProtocol, SAModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (BOOL)hasSecretKey {
    return self.encryptManager.hasSecretKey;
}

- (nullable NSDictionary *)encryptJSONObject:(nonnull id)obj {
    return [self.encryptManager encryptJSONObject:obj];
}

- (void)handleEncryptWithConfig:(nonnull NSDictionary *)encryptConfig {
    [self.encryptManager handleEncryptWithConfig:encryptConfig];
}

@end

#pragma mark -

@implementation SAModuleManager (Deeplink)

- (id<SADeeplinkModuleProtocol>)deeplinkManager {
    id module = [self moduleWithName:kSADeeplinkModuleName];
    if ([module conformsToProtocol:@protocol(SADeeplinkModuleProtocol)] && [module conformsToProtocol:@protocol(SAModuleProtocol)]) {
        id<SADeeplinkModuleProtocol, SAModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (void)setLinkHandlerCallback:(void (^ _Nonnull)(NSString * _Nullable, BOOL, NSInteger))linkHandlerCallback {
    [self.deeplinkManager setLinkHandlerCallback:linkHandlerCallback];
}

- (NSDictionary *)latestUtmProperties {
    return self.deeplinkManager.latestUtmProperties;
}

- (NSDictionary *)utmProperties {
    return self.deeplinkManager.utmProperties;
}

- (void)clearUtmProperties {
    [self.deeplinkManager clearUtmProperties];
}

- (void)trackDeepLinkLaunchWithURL:(NSString *)url {
    [self.deeplinkManager trackDeepLinkLaunchWithURL:url];
}

@end

#pragma mark -

@implementation SAModuleManager (AutoTrack)

- (id<SAAutoTrackModuleProtocol>)autoTrackManager {
    id module = [self moduleWithName:kSAAutoTrackModuleName];
    if ([module conformsToProtocol:@protocol(SAAutoTrackModuleProtocol)] && [module conformsToProtocol:@protocol(SAModuleProtocol)]) {
        id<SAAutoTrackModuleProtocol, SAModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (void)trackAppEndWhenCrashed {
    [self.autoTrackManager trackAppEndWhenCrashed];
}

- (void)trackPageLeaveWhenCrashed {
    [self.autoTrackManager trackPageLeaveWhenCrashed];
}

@end

#pragma mark -

@implementation SAModuleManager (Visualized)

- (id<SAVisualizedModuleProtocol>)visualizedManager {
    id module = [self moduleWithName:kSAVisualizedModuleName];
    if ([module conformsToProtocol:@protocol(SAVisualizedModuleProtocol)] && [module conformsToProtocol:@protocol(SAModuleProtocol)]) {
        id<SAVisualizedModuleProtocol, SAModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

#pragma mark properties
// 采集元素属性
- (nullable NSDictionary *)propertiesWithView:(id)view {
    return [self.visualizedManager propertiesWithView:view];
}

#pragma mark visualProperties
// 采集元素自定义属性
- (void)visualPropertiesWithView:(id)view completionHandler:(void (^)(NSDictionary *_Nullable))completionHandler {
    id<SAVisualizedModuleProtocol> manager = self.visualizedManager;
    if (!manager) {
        return completionHandler(nil);
    }
    [self.visualizedManager visualPropertiesWithView:view completionHandler:completionHandler];
}

// 根据属性配置，采集 App 属性值
- (void)queryVisualPropertiesWithConfigs:(NSArray <NSDictionary *>*)propertyConfigs completionHandler:(void (^)(NSDictionary *_Nullable properties))completionHandler {
    id<SAVisualizedModuleProtocol> manager = self.visualizedManager;
    if (!manager) {
        return completionHandler(nil);
    }
    [manager queryVisualPropertiesWithConfigs:propertyConfigs completionHandler:completionHandler];
}

@end

#pragma mark -

@implementation SAModuleManager (JavaScriptBridge)

- (NSString *)javaScriptSource {
    NSMutableString *source = [NSMutableString string];
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            return source;
        }
        if ([module conformsToProtocol:@protocol(SAJavaScriptBridgeModuleProtocol)] && [module respondsToSelector:@selector(javaScriptSource)] && [module conformsToProtocol:@protocol(SAModuleProtocol)]) {
            id<SAJavaScriptBridgeModuleProtocol, SAModuleProtocol>moduleObject = module;
            NSString *javaScriptSource = [moduleObject javaScriptSource];
            moduleObject.isEnable && javaScriptSource.length > 0 ? [source appendString:javaScriptSource] : nil;
        }
    }
    return source;
}

@end

@implementation SAModuleManager (RemoteConfig)

- (id<SARemoteConfigModuleProtocol>)remoteConfigManager {
    id module = [self moduleWithName:kSARemoteConfigModuleName];
    if ([module conformsToProtocol:@protocol(SARemoteConfigModuleProtocol)] && [module conformsToProtocol:@protocol(SAModuleProtocol)]) {
        id<SARemoteConfigModuleProtocol, SAModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    [self.remoteConfigManager retryRequestRemoteConfigWithForceUpdateFlag:isForceUpdate];
}

- (BOOL)isIgnoreEventObject:(SABaseEventObject *)obj {
    return [self.remoteConfigManager isIgnoreEventObject:obj];
}

@end
