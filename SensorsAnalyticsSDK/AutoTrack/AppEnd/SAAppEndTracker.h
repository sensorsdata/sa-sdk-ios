//
// SAAppEndTracker.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/2.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAAppTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAppEndTracker : SAAppTracker

/// 触发全埋点退出事件
- (void)autoTrackEvent;

/// 开始退出事件计时
- (void)trackTimerStartAppEnd;

@end

NS_ASSUME_NONNULL_END
