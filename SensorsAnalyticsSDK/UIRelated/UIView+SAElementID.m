//
// UIView+SAElementID.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/30.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+SAElementID.h"
#import "UIView+SensorsAnalytics.h"

@implementation UIView (SAElementID)

- (NSString *)sensorsdata_elementId {
    return self.sensorsAnalyticsViewID;
}

@end
