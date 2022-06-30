//
// SATrackTimer.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2019/12/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

#import "SATrackTimer.h"
#import "SAConstants+Private.h"

@interface SATrackTimer ()

@property (nonatomic, strong) NSMutableDictionary *eventNames;
@property (nonatomic, strong) NSMutableDictionary *eventIds;

@end

@implementation SATrackTimer

#pragma mark - properties lazy load
- (NSMutableDictionary *)eventNames {
    if (!_eventNames) {
        _eventNames = [[NSMutableDictionary alloc] init];
    }
    return _eventNames;
}

- (NSMutableDictionary *)eventIds {
    if (!_eventIds) {
        _eventIds = [[NSMutableDictionary alloc] init];
    }
    return _eventIds;
}

#pragma mark - public methods
- (NSString *)generateEventIdByEventName:(NSString *)eventName {
    NSString *eventId = eventName;
    if (eventId == nil || eventId.length == 0) {
        return eventId;
    }
    if (![eventName hasSuffix:kSAEventIdSuffix]) {
        //生成计时事件的 eventId，结构为 {eventName}_{uuid}_SATimer
        //uuid 字符串中 ‘-’ 是不合法字符，替换为 ‘_’
        NSString *uuid = [NSUUID.UUID.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
        eventId = [NSString stringWithFormat:@"%@_%@%@", eventName, uuid, kSAEventIdSuffix];
    }
    return eventId;
}

- (void)trackTimerStart:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime {
    return [self trackTimerStart:eventId timeUnit:SensorsAnalyticsTimeUnitSeconds currentSysUpTime:currentSysUpTime];
}

- (void)trackTimerStart:(NSString *)eventId timeUnit:(SensorsAnalyticsTimeUnit)timeUnit currentSysUpTime:(UInt64)currentSysUpTime {
    NSDictionary *params = @{@"eventBegin" : @(currentSysUpTime), @"eventAccumulatedDuration" : @(0.0), @"timeUnit" : @(timeUnit),@"isPause":@(NO)};
    self.eventIds[eventId] = params;
    NSString *eventName = [self eventNameFromEventId:eventId];
    self.eventNames[eventName] = params;
}

- (void)trackTimerPause:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime {
    //此处根据优先级先查找 eventIds 表再查找 eventNames 表，如果 eventIds 表匹配成功停止后续查询
    if ([self handleEventPause:eventId mapping:self.eventIds currentSystemUpTime:currentSysUpTime]) {
        return;
    }
    [self handleEventPause:eventId mapping:self.eventNames currentSystemUpTime:currentSysUpTime];
}

- (void)trackTimerResume:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime {
    //此处根据优先级先查找 eventIds 表再查找 eventNames 表，如果 eventIds 表匹配成功停止后续查询
    if ([self handleEventResume:eventId mapping:self.eventIds currentSystemUpTime:currentSysUpTime]) {
        return;
    }
    [self handleEventResume:eventId mapping:self.eventNames currentSystemUpTime:currentSysUpTime];
}

- (void)trackTimerRemove:(NSString *)eventId {
    if (self.eventIds[eventId]) {
        [self.eventIds removeObjectForKey:eventId];
        return;
    }
    if (self.eventNames[eventId]) {
        [self.eventNames removeObjectForKey:eventId];
    }
}

- (NSString *)eventNameFromEventId:(NSString *)eventId {
    if (![eventId hasSuffix:kSAEventIdSuffix]) {
        return eventId;
    }
    //eventId 结构为 {eventName}_D3AC265B_3CC2_4C45_B8F0_3E05A83A9DAE_SATimer，新增后缀长度为 44
    NSString *eventName = [eventId substringToIndex:(eventId.length - 1) - 44];
    return eventName;
}

- (nullable NSNumber *)eventDurationFromEventId:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime {
    //为了保证获取事件时长的准确性，计算时长时需要从外部传入当前系统开机时间
    //事件计时 eventIds 表优先级更高，在 eventIds 表中查询不到时再查询 eventNames 表
    NSNumber *duration = [self handleEventDuration:eventId mapping:self.eventIds currentSystemUpTime:currentSysUpTime];
    if (!duration) {
        duration = [self handleEventDuration:eventId mapping:self.eventNames currentSystemUpTime:currentSysUpTime];
    }
    return duration;
}

#pragma mark - operation all timing events
- (void)pauseAllEventTimers:(UInt64)currentSysUpTime {
    // 遍历 trackTimer
    // eventAccumulatedDuration = eventAccumulatedDuration + currentSystemUpTime - eventBegin
    [self handleAllEventsPause:self.eventIds time:currentSysUpTime];
    [self handleAllEventsPause:self.eventNames time:currentSysUpTime];
}

- (void)resumeAllEventTimers:(UInt64)currentSysUpTime {
    //当前逻辑只会在 App 进入到前台时调用
    // 遍历 trackTimer ,修改 eventBegin 为当前 currentSystemUpTime
    //此处逻辑和恢复单个事件计时不同，恢复所有事件时不更改 isPause 状态，只修改事件开始时间 eventBegin
    for (NSString *key in self.eventIds.allKeys) {
        NSMutableDictionary *eventTimer = [[NSMutableDictionary alloc] initWithDictionary:self.eventIds[key]];
        if (eventTimer) {
            [eventTimer setValue:@(currentSysUpTime) forKey:@"eventBegin"];
            self.eventIds[key] = eventTimer;
        }
    }
    for (NSString *key in self.eventNames.allKeys) {
        NSMutableDictionary *eventTimer = [[NSMutableDictionary alloc] initWithDictionary:self.eventNames[key]];
        if (eventTimer) {
            [eventTimer setValue:@(currentSysUpTime) forKey:@"eventBegin"];
            self.eventNames[key] = eventTimer;
        }
    }
}

- (void)clearAllEventTimers {
    [self.eventNames removeAllObjects];
    [self.eventIds removeAllObjects];
}

#pragma mark - private methods
- (UInt64)getSystemUpTime {
    return NSProcessInfo.processInfo.systemUptime * 1000;
}

- (NSNumber *)handleEventDuration:(NSString *)eventId mapping:(NSMutableDictionary *)mapping currentSystemUpTime:(UInt64)currentSystemUpTime {
    NSDictionary *eventTimer = mapping[eventId];
    if (!eventTimer) {
        return nil;
    }
    [mapping removeObjectForKey:eventId];
    NSNumber *eventBegin = [eventTimer valueForKey:@"eventBegin"];
    NSNumber *eventAccumulatedDuration = [eventTimer objectForKey:@"eventAccumulatedDuration"];
    SensorsAnalyticsTimeUnit timeUnit = [[eventTimer valueForKey:@"timeUnit"] intValue];
    BOOL isPause = [eventTimer[@"isPause"] boolValue];

    float eventDuration = 0;
    if (!isPause) {
        eventDuration = [self eventTimerDurationWithCurrentTime:currentSystemUpTime eventStart:eventBegin.longValue timeUnit:timeUnit];
    }

    if (eventAccumulatedDuration) {
        eventDuration += eventAccumulatedDuration.floatValue;
    }

    return @([[NSString stringWithFormat:@"%.3f", eventDuration] floatValue]);
}

- (BOOL)handleEventPause:(NSString *)eventId mapping:(NSMutableDictionary *)mapping currentSystemUpTime:(UInt64)currentSystemUpTime {
    NSMutableDictionary *eventTimer = [mapping[eventId] mutableCopy];
    BOOL isPause = [eventTimer[@"isPause"] boolValue];

    if (eventTimer && !isPause) {
        UInt64 eventBegin = [eventTimer[@"eventBegin"] longValue];
        SensorsAnalyticsTimeUnit timeUnit = [[eventTimer valueForKey:@"timeUnit"] intValue];

        isPause = YES;
        float eventDuration = [self eventTimerDurationWithCurrentTime:currentSystemUpTime eventStart:eventBegin timeUnit:timeUnit];

        eventTimer[@"eventBegin"] = @(eventBegin);
        eventTimer[@"isPause"] = @(isPause);
        if (eventDuration > 0) {
            eventTimer[@"eventAccumulatedDuration"] = @([eventTimer[@"eventAccumulatedDuration"] floatValue] + eventDuration);
        }
        mapping[eventId] = [eventTimer copy];
        return YES;
    }
    return NO;
}

- (BOOL)handleEventResume:(NSString *)eventId mapping:(NSMutableDictionary *)mapping currentSystemUpTime:(UInt64)currentSystemUpTime {
    NSMutableDictionary *eventTimer = [mapping[eventId] mutableCopy];
    BOOL isPause = [eventTimer[@"isPause"] boolValue];
    if (eventTimer && isPause) {
        isPause = NO;
        eventTimer[@"eventBegin"] = @(currentSystemUpTime);
        eventTimer[@"isPause"] = @(isPause);
        mapping[eventId] = [eventTimer copy];
        return YES;
    }
    return NO;
}

- (void)handleAllEventsPause:(NSMutableDictionary *)mapping time:(UInt64)currentSystemUpTime {
    for (NSString *key in mapping.allKeys) {
        if (key != nil) {
            if ([key isEqualToString:kSAEventNameAppEnd]) {
                continue;
            }
        }
        //当前逻辑只会在 App 进入到后台时调用
        //此处逻辑和暂停单个事件计时不同，暂停所有事件时不更改 isPause 状态，只累加已累计时长
        NSMutableDictionary *eventTimer = [[NSMutableDictionary alloc] initWithDictionary:mapping[key]];
        if (eventTimer && ![eventTimer[@"isPause"] boolValue]) {
            UInt64 eventBegin = [[eventTimer valueForKey:@"eventBegin"] longValue];
            NSNumber *eventAccumulatedDuration = [eventTimer objectForKey:@"eventAccumulatedDuration"];
            SensorsAnalyticsTimeUnit timeUnit = [[eventTimer valueForKey:@"timeUnit"] intValue];
            float eventDuration = [self eventTimerDurationWithCurrentTime:currentSystemUpTime eventStart:eventBegin timeUnit:timeUnit];
            if (eventAccumulatedDuration) {
                eventDuration += [eventAccumulatedDuration floatValue];
            }
            [eventTimer setObject:@(eventDuration) forKey:@"eventAccumulatedDuration"];
            [eventTimer setObject:@(currentSystemUpTime) forKey:@"eventBegin"];
            mapping[key] = eventTimer;
        }
    }
}

//计算事件时长
- (float)eventTimerDurationWithCurrentTime:(UInt64)currentSystemUpTime eventStart:(UInt64)startTime timeUnit:(SensorsAnalyticsTimeUnit)timeUnit {
    if (startTime <= 0) {
        return 0;
    }
    float eventDuration = currentSystemUpTime - startTime;
    if (eventDuration > 0 && eventDuration < 24 * 60 * 60 * 1000) {
        switch (timeUnit) {
            case SensorsAnalyticsTimeUnitHours:
                eventDuration = eventDuration / 60.0;
            case SensorsAnalyticsTimeUnitMinutes:
                eventDuration = eventDuration / 60.0;
            case SensorsAnalyticsTimeUnitSeconds:
                eventDuration = eventDuration / 1000.0;
            case SensorsAnalyticsTimeUnitMilliseconds:
                break;
        }
    } else {
        eventDuration = 0;
    }
    return eventDuration;
}

@end
