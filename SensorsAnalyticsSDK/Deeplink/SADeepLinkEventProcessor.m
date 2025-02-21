//
// SADeepLinkEventProcessor.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2022/3/14.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SADeepLinkEventProcessor.h"

@implementation SADeepLinkEventProcessor

- (void)startWithProperties:(NSDictionary *)properties {
    [self trackDeepLinkLaunch:properties];
}

@end
