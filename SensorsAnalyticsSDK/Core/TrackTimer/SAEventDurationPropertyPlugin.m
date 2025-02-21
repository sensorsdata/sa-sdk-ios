//
// SAEventDurationPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/4/24.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAEventDurationPropertyPlugin.h"
#import "SAConstants+Private.h"
#import "SAPropertyPlugin+SAPrivate.h"
#import "SABaseEventObject.h"

@interface SAEventDurationPropertyPlugin()
@property (nonatomic, weak) SATrackTimer *trackTimer;
@end

@implementation SAEventDurationPropertyPlugin

- (instancetype)initWithTrackTimer:(SATrackTimer *)trackTimer {
    NSAssert(trackTimer, @"You must initialize trackTimer");
    if (!trackTimer) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.trackTimer = trackTimer;
    }
    return self;
}

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    // 不支持 H5 打通事件
    if ([filter hybridH5]) {
        return NO;
    }
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    if (![self.filter isKindOfClass:SABaseEventObject.class]) {
        return nil;
    }

    SABaseEventObject *eventObject = (SABaseEventObject *)self.filter;
    NSNumber *eventDuration = [self.trackTimer eventDurationFromEventId:eventObject.eventId currentSysUpTime:eventObject.currentSystemUpTime];
    if (!eventDuration) {
        return nil;
    }
    return @{@"event_duration": eventDuration};
}

@end
