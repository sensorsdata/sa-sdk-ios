//
// SensorsAnalyticsSDK+Visualized.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/25.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK+Visualized.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAModuleManager+Visualized.h"
#import "SAVisualizedManager.h"

@implementation SensorsAnalyticsSDK (Visualized)

#pragma mark - VisualizedAutoTrack
- (BOOL)isVisualizedAutoTrackEnabled {
    return self.configOptions.enableVisualizedAutoTrack;
}

- (void)addVisualizedAutoTrackViewControllers:(NSArray<NSString *> *)controllers {
    [[SAVisualizedManager sharedInstance] addVisualizeWithViewControllers:controllers];
}

- (BOOL)isVisualizedAutoTrackViewController:(UIViewController *)viewController {
    return [[SAVisualizedManager sharedInstance] isVisualizeWithViewController:viewController];
}

- (void)enableVisualizedAutoTrack {
    self.configOptions.enableVisualizedAutoTrack = YES;
    [self enableVisualize];
}

#pragma mark - HeatMap
- (BOOL)isHeatMapEnabled {
    return self.configOptions.enableHeatMap;
}

- (void)addHeatMapViewControllers:(NSArray<NSString *> *)controllers {
    [[SAVisualizedManager sharedInstance] addVisualizeWithViewControllers:controllers];
}

- (BOOL)isHeatMapViewController:(UIViewController *)viewController {
    return [[SAVisualizedManager sharedInstance] isVisualizeWithViewController:viewController];
}

- (void)enableHeatMap {
    self.configOptions.enableHeatMap = YES;
    [self enableVisualize];
}

- (BOOL)handleHeatMapUrl:(NSURL *)URL {
    return [SAModuleManager.sharedInstance handleURL:URL];
}

@end
