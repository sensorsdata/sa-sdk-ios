//
// SAPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/24.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAPropertyPlugin.h"
#import "SAPropertyPlugin+SAPrivate.h"

@implementation SAPropertyPlugin

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityDefault;
}

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    return YES;
}

@end

#pragma mark -

@implementation SAPropertyPlugin (SAPublic)

- (void)readyWithProperties:(NSDictionary<NSString *, id> *)properties {
    self.properties = properties;
    if (self.handler) {
        self.handler(properties);
    }
}

@end
