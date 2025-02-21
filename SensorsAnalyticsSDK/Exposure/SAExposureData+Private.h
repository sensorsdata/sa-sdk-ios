//
// SAExposureData+Private.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/12.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAExposureData.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAExposureData (Private)

@property (nonatomic, copy) SAExposureConfig *config;
@property (nonatomic, copy) NSDictionary *properties;

/// updated properties from method updateExposure:withProperties:
@property (nonatomic, copy) NSDictionary *updatedProperties;

@end

NS_ASSUME_NONNULL_END
