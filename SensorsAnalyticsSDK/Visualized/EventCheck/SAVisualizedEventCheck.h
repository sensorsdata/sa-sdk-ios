//
// SAVisualizedEventCheck.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/3/22.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAVisualPropertiesConfigSources.h"

NS_ASSUME_NONNULL_BEGIN

/// 可视化全埋点埋点校验
@interface SAVisualizedEventCheck : NSObject
- (instancetype)initWithConfigSources:(SAVisualPropertiesConfigSources *)configSources;

/// 筛选事件结果
@property (nonatomic, strong, readonly) NSArray<NSDictionary *> *eventCheckResult;

/// 清除调试事件
- (void)cleanEventCheckResult;
@end

NS_ASSUME_NONNULL_END
