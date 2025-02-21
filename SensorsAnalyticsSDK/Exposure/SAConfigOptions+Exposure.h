//
// SAConfigOptions+Exposure.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "SAConfigOptions.h"
#import "SAExposureConfig.h"
#import "SAExposureData.h"
#import "SensorsAnalyticsSDK+Exposure.h"
#import "UIView+ExposureIdentifier.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (Exposure)

/// global exposure config settings, default value with areaRate = 0, stayDuration = 0, repeated = YES
@property (nonatomic, copy) SAExposureConfig *exposureConfig;

@end

NS_ASSUME_NONNULL_END
