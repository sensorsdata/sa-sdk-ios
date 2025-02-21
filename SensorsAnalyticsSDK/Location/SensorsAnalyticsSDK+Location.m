//
// SensorsAnalyticsSDK+Location.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK+Location.h"
#import "SALocationManager.h"

@implementation SensorsAnalyticsSDK (Location)

- (void)enableTrackGPSLocation:(BOOL)enable {
    if (NSThread.isMainThread) {
        [SALocationManager defaultManager].enable = enable;
        [SALocationManager defaultManager].configOptions.enableLocation = enable;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [SALocationManager defaultManager].enable = enable;
            [SALocationManager defaultManager].configOptions.enableLocation = enable;
        });
    }
}

@end
