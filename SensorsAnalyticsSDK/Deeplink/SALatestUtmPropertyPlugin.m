//
// SALatestUtmPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/4/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SALatestUtmPropertyPlugin.h"
#import "SAModuleManager.h"
#import "SADeepLinkConstants.h"
#import "SAConstants+Private.h"

@implementation SALatestUtmPropertyPlugin

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    // 手动调用接口采集 $AppDeeplinkLaunch 事件, 不需要添加 $latest_utm_xxx 属性
    if ([self.filter.event isEqualToString:kSAAppDeepLinkLaunchEvent] && [self.filter.lib.method isEqualToString:kSALibMethodCode]) {
        return NO;
    }
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    return SAModuleManager.sharedInstance.latestUtmProperties;
}

@end
