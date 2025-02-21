//
// SensorsAnalyticsSDK+DeviceOrientation.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SensorsAnalyticsSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK (DeviceOrientation)

/**
 * @abstract
 * 设备方向信息采集功能开关
 *
 * @discussion
 * 根据需要决定是否开启设备方向采集
 * 默认关闭
 *
 * @param enable YES/NO
 */
- (void)enableTrackScreenOrientation:(BOOL)enable API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("DeviceOrientation not supported for iOS extensions.");

@end

NS_ASSUME_NONNULL_END
