//
// SASessionProperty.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/12/23.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SASessionProperty : NSObject

/// 设置事件间隔最大时长，默认值为 5 * 60 * 1000 毫秒。单位为毫秒
- (instancetype)initWithMaxInterval:(NSInteger)maxInterval NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// 移除本地保存的 session 信息
+ (void)removeSessionModel;

/// 获取 session 相关属性
/// @param eventTime 事件触发的时间
- (NSDictionary *)sessionPropertiesWithEventTime:(NSNumber *)eventTime;

@end

NS_ASSUME_NONNULL_END
