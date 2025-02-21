//
// SAConfigOptions+Exception.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAConfigOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (Exception)

/// 是否自动收集 App Crash 日志，该功能默认是关闭的
@property (nonatomic, assign) BOOL enableTrackAppCrash API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("Exception not supported for iOS extensions.");

@end

NS_ASSUME_NONNULL_END
