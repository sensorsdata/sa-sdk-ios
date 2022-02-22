//
// SAPropertyPluginProtocol.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/9/6.
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, SAPropertyPluginEventTypes) {
    SAPropertyPluginEventTypeTrack = 1 << 0,
    SAPropertyPluginEventTypeSignup = 1 << 1,
    SAPropertyPluginEventTypeProfileSet = 1 << 2,
    SAPropertyPluginEventTypeProfileSetOnce = 1 << 3,
    SAPropertyPluginEventTypeProfileUnset = 1 << 4,
    SAPropertyPluginEventTypeProfileDelete = 1 << 5,
    SAPropertyPluginEventTypeProfileAppend = 1 << 6,
    SAPropertyPluginEventTypeIncrement = 1 << 7,
    SAPropertyPluginEventTypeItemSet = 1 << 8,
    SAPropertyPluginEventTypeItemDelete = 1 << 9,
    SAPropertyPluginEventTypeBind = 1 << 10,
    SAPropertyPluginEventTypeUnbind = 1 << 11,
    SAPropertyPluginEventTypeAll = 0xFFFFFFFF,
};

typedef NS_ENUM(NSUInteger, SAPropertyPluginPriority) {
    SAPropertyPluginPriorityLow = 250,
    SAPropertyPluginPriorityDefault = 500,
    SAPropertyPluginPriorityHigh = 750,
};

typedef void(^SAPropertyPluginCompletion)(NSDictionary<NSString *, id> *properties);

@protocol SAPropertyPluginProtocol <NSObject>

/// 属性插件采集的属性
///
/// @return 属性
- (NSDictionary<NSString *, id> *)properties;

@optional

/// 开始属性采集
///
/// 该方法在触发事件的队列中执行，如果是 UI 操作，需要切换到主线程
- (void)start;

/// 事件名称
///
/// 如果不实现则表示为所有事件添加，返回 nil 则所有事件均不添加属性
- (nullable NSArray<NSString *> *)eventNameFilter;

/// 事件类型
///
/// 如果不实现则使用默认值 SAPropertyPluginEventTypeTrack
- (SAPropertyPluginEventTypes)eventTypeFilter;

/// 事件的自定义属性
///
/// 如果不实现则不进行筛选
- (nullable NSArray<NSString *> *)propertyKeyFilter;

/// 属性优先级
///
/// 默认为： SAPropertyPluginPriorityDefault
- (SAPropertyPluginPriority)priority;

/// 设置属性插件回调
/// 如果是异步操作，需要实现这个方法，并在异步操作结束时，调用回调接口。
///
/// @param completion 回调
- (void)setPropertyPluginCompletion:(SAPropertyPluginCompletion)completion;

@end

NS_ASSUME_NONNULL_END
