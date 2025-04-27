//
// SensorsAnalyticsSDK+DebugMode.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SensorsAnalyticsSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK (DebugMode)

/**
 * @abstract
 * 设置是否显示 debugInfoView，对于 iOS，是 UIAlertView／UIAlertController
 *
 * @discussion
 * 设置是否显示 debugInfoView，默认显示
 *
 * @param show             是否显示
 */
- (void)showDebugInfoView:(BOOL)show API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("DebugMode not supported for iOS extensions.");

- (SensorsAnalyticsDebugMode)debugMode;

@end

NS_ASSUME_NONNULL_END
