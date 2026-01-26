//
// SensorsAnalyticsSDK+Visualized.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/25.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SensorsAnalyticsSDK.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK (Visualized)

/**
 是否开启 可视化全埋点 分析，默认不

 @return YES/NO
 */
- (BOOL)isVisualizedAutoTrackEnabled;

/**
 指定哪些页面开启 可视化全埋点 分析，
 如果指定了页面，只有这些页面的 $AppClick 事件会采集控件的 viewPath。

 @param controllers 指定的页面的类名数组
 */
- (void)addVisualizedAutoTrackViewControllers:(NSArray<NSString *> *)controllers NS_EXTENSION_UNAVAILABLE("VisualizedAutoTrack not supported for iOS extensions.");

/**
 某个页面是否开启 可视化全埋点 分析。

 @param viewController 页面 viewController
 @return YES/NO
 */
- (BOOL)isVisualizedAutoTrackViewController:(UIViewController *)viewController;

#pragma mark HeatMap

/**
 是否开启点击图

 @return YES/NO 是否开启了点击图
 */
- (BOOL)isHeatMapEnabled;

/**
 指定哪些页面开启 HeatMap，如果指定了页面
 只有这些页面的 $AppClick 事件会采集控件的 viewPath

 @param controllers 需要开启点击图的 ViewController 的类名
 */
- (void)addHeatMapViewControllers:(NSArray<NSString *> *)controllers NS_EXTENSION_UNAVAILABLE("HeatMap not supported for iOS extensions.");

/**
 当前页面是否开启 点击图 分析。

 @param viewController 当前页面 viewController
 @return 当前 viewController 是否支持点击图分析
 */
- (BOOL)isHeatMapViewController:(UIViewController *)viewController;

@end

@interface SAConfigOptions (Visualized)

/// 开启点击图
@property (nonatomic, assign) BOOL enableHeatMap API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("HeatMap not supported for iOS extensions.");

/// 开启可视化全埋点
@property (nonatomic, assign) BOOL enableVisualizedAutoTrack API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("VisualizedAutoTrack not supported for iOS extensions.");

/// 开启可视化全埋点自定义属性
///
/// 开启后，SDK 会默认开启可视化全埋点功能
@property (nonatomic, assign) BOOL enableVisualizedProperties API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("VisualizedAutoTrack not supported for iOS extensions.");

@end

NS_ASSUME_NONNULL_END
