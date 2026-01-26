//
// SAConfigOptions+AppPush.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAConfigOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (AppPush)

///开启自动采集通知
@property (nonatomic, assign) BOOL enableTrackPush API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("AppPush not supported for iOS extensions.");

@end

NS_ASSUME_NONNULL_END
