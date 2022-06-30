//
// SAEventObjectFactory.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/26.
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
