//
// SAFirstDayPropertyPlugin.h
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/5.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

/// 是否首日属性采集插件
@interface SAFirstDayPropertyPlugin : SAPropertyPlugin

- (instancetype)initWithQueue:(dispatch_queue_t)queue;

- (BOOL)isFirstDay;

@end

NS_ASSUME_NONNULL_END
