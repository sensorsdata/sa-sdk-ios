//
// SAEventObjectFactory.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAEventObjectFactory.h"
#import "SAProfileEventObject.h"
#import "SATrackEventObject.h"
#import "SAItemEventObject.h"
#import "SAConstants+Private.h"

@implementation SAEventObjectFactory

+ (SABaseEventObject *)eventObjectWithH5Event:(NSDictionary *)event {
    NSString *type = event[kSAEventType];
    if ([type isEqualToString:kSAEventTypeTrack]) {
        return [[SACustomEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kSAEventTypeSignup]) {
        return [[SASignUpEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kSAEventTypeBind]) {
        return [[SABindEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kSAEventTypeUnbind]) {
        return [[SAUnbindEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kSAProfileSet]) {
        return [[SAProfileEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kSAProfileSetOnce]) {
        return [[SAProfileEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kSAProfileUnset]) {
        return [[SAProfileEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kSAProfileDelete]) {
        return [[SAProfileEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kSAProfileAppend]) {
        return [[SAProfileAppendEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kSAProfileIncrement]) {
        return [[SAProfileIncrementEventObject alloc] initWithH5Event:event];
    }
    // H5 打通暂不支持 item 事件
    return [[SABaseEventObject alloc] initWithH5Event:event];
}

@end
