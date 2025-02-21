//
// SAReferrerTitlePropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/4/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAReferrerTitlePropertyPlugin.h"
#import "SAReferrerManager.h"
#import "SAConstants+Private.h"
#import "SAPropertyPlugin+SAPrivate.h"

@implementation SAReferrerTitlePropertyPlugin

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    // 不支持 H5 打通事件
    if ([filter hybridH5]) {
        return NO;
    }
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    NSString *referrerTitle = [SAReferrerManager.sharedInstance referrerTitle];
    if (!referrerTitle) {
        return nil;
    }
    return @{kSAEeventPropertyReferrerTitle: referrerTitle};
}

@end
