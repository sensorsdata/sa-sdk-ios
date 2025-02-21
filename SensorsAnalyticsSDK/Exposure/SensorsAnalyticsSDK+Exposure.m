//
// SensorsAnalyticsSDK+Exposure.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK+Exposure.h"
#import "SAExposureManager.h"

@implementation SensorsAnalyticsSDK (Exposure)

- (void)addExposureView:(UIView *)view withData:(SAExposureData *)data {
    [[SAExposureManager defaultManager] addExposureView:view withData:data];
}

- (void)removeExposureView:(UIView *)view withExposureIdentifier:(NSString *)identifier {
    [[SAExposureManager defaultManager] removeExposureView:view withExposureIdentifier:identifier];
}

- (void)updateExposure:(UIView *)view withProperties:(NSDictionary *)properties {
    [[SAExposureManager defaultManager] updateExposure:view withProperties:properties];
}

@end
