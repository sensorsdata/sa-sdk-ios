//
// SensorsAnalyticsSDK+Visualized.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/25.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK+Visualized.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAVisualizedManager.h"

@implementation SensorsAnalyticsSDK (Visualized)

#pragma mark - VisualizedAutoTrack
- (BOOL)isVisualizedAutoTrackEnabled NS_EXTENSION_UNAVAILABLE("VisualizedAutoTrack not supported for iOS extensions.") {
    return self.configOptions.enableVisualizedAutoTrack || self.configOptions.enableVisualizedProperties;
}

- (void)addVisualizedAutoTrackViewControllers:(NSArray<NSString *> *)controllers {
    [[SAVisualizedManager defaultManager] addVisualizeWithViewControllers:controllers];
}

- (BOOL)isVisualizedAutoTrackViewController:(UIViewController *)viewController {
    return [[SAVisualizedManager defaultManager] isVisualizeWithViewController:viewController];
}

#pragma mark - HeatMap
- (BOOL)isHeatMapEnabled NS_EXTENSION_UNAVAILABLE("HeatMap not supported for iOS extensions.") {
    return self.configOptions.enableHeatMap;
}

- (void)addHeatMapViewControllers:(NSArray<NSString *> *)controllers {
    [[SAVisualizedManager defaultManager] addVisualizeWithViewControllers:controllers];
}

- (BOOL)isHeatMapViewController:(UIViewController *)viewController {
    return [[SAVisualizedManager defaultManager] isVisualizeWithViewController:viewController];
}

@end
