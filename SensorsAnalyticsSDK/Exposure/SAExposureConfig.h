//
// SAExposureConfig.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAExposureConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// init method
/// @param areaRate visable area rate, 0 ~ 1, default value is 0
/// @param stayDuration stay duration, default value is 0, unit is second
/// @param repeated allow repeated exposure, default value is YES
- (instancetype)initWithAreaRate:(CGFloat)areaRate stayDuration:(NSTimeInterval)stayDuration repeated:(BOOL)repeated;

@end

NS_ASSUME_NONNULL_END
