//
// SAExposureConfig+Private.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAExposureConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAExposureConfig (Private)

/// visable area rate, 0 ~ 1, default value is 0
@property (nonatomic, assign, readonly) CGFloat areaRate;

/// stay duration, default value is 0, unit is second
@property (nonatomic, assign, readonly) NSTimeInterval stayDuration;

/// allow repeated exposure or not, default value is YES
@property (nonatomic, assign, readonly) BOOL repeated;

@end

NS_ASSUME_NONNULL_END
