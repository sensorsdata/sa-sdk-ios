//
// SAAppVersionPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/1/12.
// Copyright © 2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAppVersionPropertyPlugin.h"

/// 应用版本
static NSString * const kSAPropertyPluginAppVersion = @"$app_version";

@interface SAAppVersionPropertyPlugin()
@property (nonatomic, copy) NSString *appVersion;
@end

@implementation SAAppVersionPropertyPlugin

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

- (void)prepare {
    self.appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSDictionary<NSString *,id> *)properties {
    if (!self.appVersion) {
        return nil;
    }
    return @{kSAPropertyPluginAppVersion: self.appVersion};
}

@end
