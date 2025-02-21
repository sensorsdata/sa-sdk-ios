//
// SAEventDurationPropertyPlugin.h
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/4/24.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPropertyPlugin.h"
#import "SATrackTimer.h"

NS_ASSUME_NONNULL_BEGIN

/// 事件时长属性插件
@interface SAEventDurationPropertyPlugin :SAPropertyPlugin


/// 事件时长属性插件初始化
/// @param trackTimer 事件计时器
- (instancetype)initWithTrackTimer:(SATrackTimer *)trackTimer NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
