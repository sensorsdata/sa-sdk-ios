//
// SAPresetPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/9/7.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAPresetPropertyPlugin.h"
#import "SAPresetPropertyObject.h"
#import "SAEventLibObject.h"

@interface SAPresetPropertyPlugin ()

@property (nonatomic, copy) NSString *libVersion;

/// 完整预置属性
@property (nonatomic, copy) NSDictionary *presetProperties;

@end

@implementation SAPresetPropertyPlugin

- (instancetype)initWithLibVersion:(NSString *)libVersion {
    self = [super init];
    if (self) {
        _libVersion = libVersion;
    }
    return self;
}

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

/// 初始化预置属性
- (void)prepare {
    SAPresetPropertyObject *propertyObject;
#if TARGET_OS_IOS
    if ([self isiOSAppOnMac]) {
        propertyObject = [[SACatalystPresetProperty alloc] init];
    } else {
        propertyObject = [[SAPhonePresetProperty alloc] init];
    }
#elif TARGET_OS_OSX
    propertyObject = [[SAMacPresetProperty alloc] init];
#elif TARGET_OS_TV
    propertyObject = [[SATVPresetProperty alloc] init];
#elif TARGET_OS_WATCH
    propertyObject = [[SAWatchPresetProperty alloc] init];
#endif

    NSMutableDictionary<NSString *, id> *properties = [NSMutableDictionary dictionary];
    [properties addEntriesFromDictionary:propertyObject.properties];
    properties[kSAEventPresetPropertyLibVersion] = self.libVersion;

    self.presetProperties = [properties copy];
}

- (NSDictionary<NSString *,id> *)properties {
    if (!self.filter.hybridH5) {
        return self.presetProperties;
    }

    // App 内嵌 H5 事件，$lib 和  $lib_version 使用 JS 的原始数据
    NSMutableDictionary *webPresetProperties = [self.presetProperties mutableCopy];
    [webPresetProperties removeObjectsForKeys:@[kSAEventPresetPropertyLib, kSAEventPresetPropertyLibVersion]];
    return [webPresetProperties copy];
}

#if TARGET_OS_IOS
- (BOOL)isiOSAppOnMac {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    if (@available(iOS 14.0, macOS 11.0, *)) {
        if ([info respondsToSelector:@selector(isiOSAppOnMac)] &&
            info.isiOSAppOnMac) {
            return YES;
        }
    }
    if (@available(iOS 13.0, macOS 10.15, *)) {
        if ([info respondsToSelector:@selector(isMacCatalystApp)] &&
            info.isMacCatalystApp) {
            return YES;
        }
    }
    return NO;
}
#endif

@end
