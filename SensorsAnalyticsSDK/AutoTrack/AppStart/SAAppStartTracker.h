//
// SAAppStartTracker.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/2.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAAppTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAppStartTracker : SAAppTracker

/// 触发全埋点启动事件
/// @param properties 事件属性
- (void)autoTrackEventWithProperties:(nullable NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
