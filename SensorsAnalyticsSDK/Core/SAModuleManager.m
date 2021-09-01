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

// Location 模块名
static NSString * const kSALocationModuleName = @"Location";
static NSString * const kSADeviceOrientationModuleName = @"DeviceOrientation";
static NSString * const kSADebugModeModuleName = @"DebugMode";
static NSString * const kSAReactNativeModuleName = @"ReactNative";
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
@property (atomic, strong) NSMutableDictionary<NSString *, id<SAModuleProtocol>> *modules;

@property (nonatomic, strong) SAConfigOptions *configOptions;

@end

@implementation SAModuleManager

+ (void)startWithConfigOptions:(SAConfigOptions *)configOptions debugMode:(SensorsAnalyticsDebugMode)debugMode {
    SAModuleManager.sharedInstance.configOptions = configOptions;
    // 禁止 SDK 时，不开启其他模块
    if (configOptions.disableSDK) {
        return;
    }

    // H5 打通模块
    if (configOptions.enableJavaScriptBridge) {
        [SAModuleManager.sharedInstance setEnable:YES forModule:kSAJavaScriptBridgeModuleName];
    }

#if TARGET_OS_IOS
    // 推送点击模块
    if (configOptions.enableTrackPush) {
        [SAModuleManager.sharedInstance setEnable:YES forModule:kSANotificationModuleName];
    }

    // 渠道联调诊断功能获取多渠道匹配开关
    [SAModuleManager.sharedInstance setEnable:YES forModule:kSAChannelMatchModuleName];

    // 初始化 LinkHandler 处理 deepLink 相关操作
    [SAModuleManager.sharedInstance setEnable:YES forModule:kSADeeplinkModuleName];

    // 初始化 Debug 模块
    [SAModuleManager.sharedInstance setEnable:YES forModule:kSADebugModeModuleName];
    [SAModuleManager.sharedInstance handleDebugMode:debugMode];

    // 默认加载全埋点模块，没有判断是否开启全埋点，原因如下：
    // 1. 同之前的逻辑保持一致
    // 2. 保证添加对于生命周期的监听在生命周期类的实例化之前
    if ([SAModuleManager.sharedInstance contains:SAModuleTypeAutoTrack] || configOptions.autoTrackEventType != SensorsAnalyticsEventTypeNone) {
        [SAModuleManager.sharedInstance setEnable:YES forModuleType:SAModuleTypeAutoTrack];
    }

    // 可视化全埋点和点击分析
    if (configOptions.enableHeatMap || configOptions.enableVisualizedAutoTrack) {
        [SAModuleManager.sharedInstance setEnable:YES forModule:kSAVisualizedModuleName];
        [SAModuleManager.sharedInstance setEnable:YES forModule:kSAJavaScriptBridgeModuleName];
    } else if ([SAModuleManager.sharedInstance contains:SAModuleTypeVisualized]) {
        // 注册 handleURL
        [SAModuleManager.sharedInstance setEnable:NO forModule:kSAVisualizedModuleName];
    }

    // 加密
    [SAModuleManager.sharedInstance setEnable:configOptions.enableEncrypt forModule:kSAEncryptModuleName];

    // crash 采集
    if (configOptions.enableTrackAppCrash) {
        [SAModuleManager.sharedInstance setEnable:YES forModule:kSAExceptionModuleName];
    }

    // 开启远程配置模块（因为部分模块依赖于远程配置，所以远程配置模块的初始化放到最后）
    [SAModuleManager.sharedInstance setEnable:YES forModule:kSARemoteConfigModuleName];

#endif

}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAModuleManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAModuleManager alloc] init];
        manager.modules = [NSMutableDictionary dictionary];
    });
    return manager;
}

#pragma mark - Private

- (NSString *)moduleNameForType:(SAModuleType)type {
    switch (type) {
        case SAModuleTypeLocation:
            return kSALocationModuleName;
        case SAModuleTypeDeviceOrientation:
            return kSADeviceOrientationModuleName;
        case SAModuleTypeReactNative:
            return kSAReactNativeModuleName;
        case SAModuleTypeAppPush:
            return kSANotificationModuleName;
        case SAModuleTypeAutoTrack:
            return kSAAutoTrackModuleName;
        case SAModuleTypeVisualized:
            return kSAVisualizedModuleName;
        case SAModuleTypeJavaScriptBridge:
            return kSAJavaScriptBridgeModuleName;
        case SAModuleTypeRemoteConfig:
            return kSARemoteConfigModuleName;
        case SAModuleTypeException:
            return kSAExceptionModuleName;
        default:
            return nil;
    }
}

- (NSString *)classNameForModule:(NSString *)moduleName {
    return [NSString stringWithFormat:@"SA%@Manager", moduleName];
}

- (void)setEnable:(BOOL)enable forModule:(NSString *)moduleName {
    if (self.modules[moduleName]) {
        self.modules[moduleName].enable = enable;
    } else {
        NSString *className = [self classNameForModule:moduleName];
        Class<SAModuleProtocol> cla = NSClassFromString(className);
        NSAssert(cla, @"\n您使用接口开启了 %@ 模块，但是并没有集成该模块。\n • 如果使用源码集成神策分析 iOS SDK，请检查是否包含名为 %@ 的文件？\n • 如果使用 CocoaPods 集成 SDK，请修改 Podfile 文件，增加 %@ 模块的 subspec，例如：pod 'SensorsAnalyticsSDK', :subspecs => ['Core', '%@']。\n", moduleName, className, moduleName, moduleName);
        if ([cla conformsToProtocol:@protocol(SAModuleProtocol)]) {
            id<SAModuleProtocol> object = [[(Class)cla alloc] init];
            if ([object respondsToSelector:@selector(setConfigOptions:)]) {
                object.configOptions = self.configOptions;
            }
            object.enable = enable;
            self.modules[moduleName] = object;
        }
    }
}

#pragma mark - Public

- (BOOL)isDisableSDK {
    if (self.configOptions.disableSDK) {
        return YES;
    }
    id<SARemoteConfigModuleProtocol, SAModuleProtocol> manager = (id<SARemoteConfigModuleProtocol, SAModuleProtocol>)self.modules[kSARemoteConfigModuleName];
    return manager.isEnable ? manager.isDisableSDK : NO;
}

- (void)disableAllModules {
    NSArray<NSString *> *allKeys = self.modules.allKeys;
    for (NSString *key in allKeys) {
        // 这两个模块是使用接口开启，所以在 SAConfigOptions 中不存在标记，无法重新开启
        // 当定位弹窗出现时，如果关闭了定位模块，会导致弹窗消失
        if (![key isEqualToString:kSALocationModuleName] &&
            ![key isEqualToString:kSADeviceOrientationModuleName] &&
            ![key isEqualToString:kSADebugModeModuleName] &&
            ![key isEqualToString:kSAEncryptModuleName]
            ) {
            [self.modules removeObjectForKey:key];
        }
    }
}

- (BOOL)contains:(SAModuleType)type {
    NSString *moduleName = [self moduleNameForType:type];
    NSString *className = [self classNameForModule:moduleName];
    return [NSClassFromString(className) conformsToProtocol:@protocol(SAModuleProtocol)];
}

- (id<SAModuleProtocol>)managerForModuleType:(SAModuleType)type {
    NSString *name = [self moduleNameForType:type];
    return self.modules[name];
}

- (void)setEnable:(BOOL)enable forModuleType:(SAModuleType)type {
    NSString *name = [self moduleNameForType:type];
    [self setEnable:enable forModule:name];
}

- (void)updateServerURL:(NSString *)serverURL {
    [self.modules enumerateKeysAndObjectsUsingBlock:^(NSString *key, id<SAModuleProtocol> obj, BOOL *stop) {
        if (!([obj conformsToProtocol:@protocol(SAModuleProtocol)] && [obj respondsToSelector:@selector(updateServerURL:)]) || !obj.isEnable) {
            return;
        }
        [obj updateServerURL:serverURL];
    }];
}

#pragma mark - Open URL

- (BOOL)canHandleURL:(NSURL *)url {
    for (id<SAModuleProtocol> obj in self.modules.allValues) {
        if (![obj conformsToProtocol:@protocol(SAOpenURLProtocol)]) {
            continue;
        }
        id<SAOpenURLProtocol> manager = (id<SAOpenURLProtocol>)obj;
        if ([manager canHandleURL:url]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)handleURL:(NSURL *)url {
    for (id<SAModuleProtocol> obj in self.modules.allValues) {
        if (![obj conformsToProtocol:@protocol(SAOpenURLProtocol)]) {
            continue;
        }
        id<SAOpenURLProtocol> manager = (id<SAOpenURLProtocol>)obj;
        if ([manager canHandleURL:url]) {
            return [manager handleURL:url];
        }
    }
    return NO;
}

@end

#pragma mark -

@implementation SAModuleManager (Property)

- (NSDictionary *)properties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 这里需要做一次 copy 操作，避免多线程中同时操作 modules 导致崩溃
    NSDictionary *dictionary = [self.modules copy];
    // 兼容使用宏定义的方式源码集成 SDK
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id<SAModuleProtocol> obj, BOOL *stop) {
        if (!([obj conformsToProtocol:@protocol(SAPropertyModuleProtocol)] && [obj respondsToSelector:@selector(properties)]) || !obj.isEnable) {
            return;
        }
        id<SAPropertyModuleProtocol> manager = (id<SAPropertyModuleProtocol>)obj;
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
        if ([key isEqualToString:kSALocationModuleName]) {
            return [properties addEntriesFromDictionary:manager.properties];
        }
#endif
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
        if ([key isEqualToString:kSADeviceOrientationModuleName]) {
            return [properties addEntriesFromDictionary:manager.properties];
        }
#endif
        if (manager.properties.count > 0) {
            [properties addEntriesFromDictionary:manager.properties];
        }
    }];
    return properties;
}

@end

#pragma mark -

@implementation SAModuleManager (ChannelMatch)

- (id<SAChannelMatchModuleProtocol>)channelMatchManager {
    id<SAChannelMatchModuleProtocol, SAModuleProtocol> manager = (id<SAChannelMatchModuleProtocol, SAModuleProtocol>)self.modules[kSAChannelMatchModuleName];
    return manager.isEnable ? manager : nil;
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
    return (id<SADebugModeModuleProtocol>)self.modules[kSADebugModeModuleName];
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
    id<SAEncryptModuleProtocol, SAModuleProtocol> manager = (id<SAEncryptModuleProtocol, SAModuleProtocol>)self.modules[kSAEncryptModuleName];
    return manager.isEnable ? manager : nil;
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
    id<SADeeplinkModuleProtocol> manager = (id<SADeeplinkModuleProtocol>)self.modules[kSADeeplinkModuleName];
    return manager;
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
    id<SAAutoTrackModuleProtocol, SAModuleProtocol> manager = (id<SAAutoTrackModuleProtocol, SAModuleProtocol>)self.modules[kSAAutoTrackModuleName];
    return manager.isEnable ? manager : nil;
}

- (void)trackAppEndWhenCrashed {
    [self.autoTrackManager trackAppEndWhenCrashed];
}

- (void)trackPageLeaveWhenCrashed {
    [self.autoTrackManager trackPageLeaveWhenCrashed];
}

@end

#pragma mark -

@implementation SAModuleManager (JavaScriptBridge)

- (NSString *)javaScriptSource {
    NSMutableString *source = [NSMutableString string];
    // 这里需要做一次 copy 操作，避免多线程中同时操作 modules 导致崩溃
    NSDictionary *dictionary = [self.modules copy];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id<SAModuleProtocol> obj, BOOL *stop) {
        if (!([obj conformsToProtocol:@protocol(SAJavaScriptBridgeModuleProtocol)] && [obj respondsToSelector:@selector(javaScriptSource)]) || !obj.isEnable) {
            return;
        }
        NSString *javaScriptSource = [(id<SAJavaScriptBridgeModuleProtocol>)obj javaScriptSource];
        if (javaScriptSource.length > 0) {
            [source appendString:javaScriptSource];
        }
    }];
    return source;
}

@end

@implementation SAModuleManager (RemoteConfig)

- (id<SARemoteConfigModuleProtocol>)remoteConfigManager {
    id<SARemoteConfigModuleProtocol, SAModuleProtocol> manager = (id<SARemoteConfigModuleProtocol, SAModuleProtocol>)self.modules[kSARemoteConfigModuleName];
    return manager.isEnable ? manager : nil;
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    [self.remoteConfigManager retryRequestRemoteConfigWithForceUpdateFlag:isForceUpdate];
}

- (BOOL)isIgnoreEventObject:(SABaseEventObject *)obj {
    return [self.remoteConfigManager isIgnoreEventObject:obj];
}

@end
