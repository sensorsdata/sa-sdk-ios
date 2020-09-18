//
// SATrackTimer.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2019/12/26.
// Copyright © 2019 SensorsData. All rights reserved.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>
#import "SAConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface SATrackTimer : NSObject

#pragma mark - generate event id
/**
 @abstract
 生成事件计时的 eventId

 @param eventName 开始计时的事件名
 @return 计时事件的 eventId
*/
- (NSString *)generateEventIdByEventName:(NSString *)eventName;

#pragma mark - track timer for event
/**
 @abstract
 开始事件计时

 @discussion
 多次调用 trackTimerStart: 时，以最后一次调用为准。

 @param eventId 开始计时的事件名或 eventId
*/
- (void)trackTimerStart:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime;

/**
 @abstract
 为了兼容废弃接口功能提供 timeUnit 入参

 @param eventId 开始计时的事件名或 eventId
 @param timeUnit 计时单位，毫秒/秒/分钟/小时
*/
- (void)trackTimerStart:(NSString *)eventId timeUnit:(SensorsAnalyticsTimeUnit)timeUnit currentSysUpTime:(UInt64)currentSysUpTime;

/**
 @abstract
 暂停事件计时

 @discussion
 多次调用 trackTimerPause: 时，以首次调用为准。

 @param eventId  trackTimerStart: 返回的 ID 或事件名
*/
- (void)trackTimerPause:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime;

/**
 @abstract
 恢复事件计时

 @discussion
 多次调用 trackTimerResume: 时，以首次调用为准。

 @param eventId trackTimerStart: 返回的 ID 或事件名
*/
- (void)trackTimerResume:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime;

/**
 @abstract
 删除事件计时

 @discussion
 多次调用 trackTimerRemove: 时，只有首次调用有效。

 @param eventId trackTimerStart: 返回的 ID 或事件名
*/
- (void)trackTimerRemove:(NSString *)eventId;

#pragma mark -
/**
 @abstract
 获取事件时长

 @param eventId trackTimerStart: 返回的 ID 或事件名
 @param currentSysUpTime 当前系统启动时间

 @return 计时事件的时长
*/
- (nullable NSNumber *)eventDurationFromEventId:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime;

/**
 @abstract
 获取计时事件原始事件名

 @param eventId trackTimerStart: 返回的 ID 或事件名
 @return 计时事件的原始事件名
*/
- (NSString *)eventNameFromEventId:(NSString *)eventId;

#pragma mark - operation all timing events
/**
 @abstract
 暂停所有计时事件
*/
- (void)pauseAllEventTimers:(UInt64)currentSysUpTime;

/**
 @abstract
 恢复所有计时事件
*/
- (void)resumeAllEventTimers:(UInt64)currentSysUpTime;

/**
 @abstract
 清除所有计时事件
*/
- (void)clearAllEventTimers;

@end

NS_ASSUME_NONNULL_END
