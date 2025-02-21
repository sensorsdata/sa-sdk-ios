//
// SensorsAnalyticsSDK+DeviceOrientation.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK+DeviceOrientation.h"
#import "SADeviceOrientationManager.h"

@implementation SensorsAnalyticsSDK (DeviceOrientation)

- (void)enableTrackScreenOrientation:(BOOL)enable {
    [SADeviceOrientationManager defaultManager].enable = enable;
    [SADeviceOrientationManager defaultManager].configOptions.enableDeviceOrientation = enable;
}

@end
