//
// SATrackEventObject.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/6.
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

#import "SATrackEventObject.h"
#import "SAConstants+Private.h"
#import "SAValidator.h"
#import "SALog.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SASessionProperty.h"

@implementation SATrackEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super init];
    if (self) {
        self.eventId = eventId && ![eventId isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"%@", eventId] : eventId;
    }
    return self;
}

- (void)validateEventWithError:(NSError **)error {
    [SAValidator validKey:self.eventId error:error];
}

@end

@implementation SASignUpEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = SAEventTypeSignup;
    }
    return self;
}

- (instancetype)initWithH5Event:(NSDictionary *)event {
    self = [super initWithH5Event:event];
    if (self) {
        self.type = SAEventTypeSignup;
    }
    return self;
}

- (NSMutableDictionary *)jsonObject {
    NSMutableDictionary *jsonObject = [super jsonObject];
    jsonObject[kSAEventOriginalId] = self.originalId;
    return jsonObject;
}

- (BOOL)isSignUp {
    return YES;
}

// $SignUp 事件不添加该属性
- (void)addModuleProperties:(NSDictionary *)properties {
}

@end

@implementation SACustomEventObject

@end

@implementation SAAutoTrackEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = SAEventTypeTrack;
        self.lib.method = kSALibMethodAuto;
    }
    return self;
}

@end

@implementation SAPresetEventObject

@end

/// 绑定 ID 事件
@implementation SABindEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = SAEventTypeBind;
    }
    return self;
}

- (instancetype)initWithH5Event:(NSDictionary *)event {
    self = [super initWithH5Event:event];
    if (self) {
        self.type = SAEventTypeBind;
    }
    return self;
}

@end

/// 解绑 ID 事件
@implementation SAUnbindEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = SAEventTypeUnbind;
    }
    return self;
}

- (instancetype)initWithH5Event:(NSDictionary *)event {
    self = [super initWithH5Event:event];
    if (self) {
        self.type = SAEventTypeUnbind;
    }
    return self;
}

@end
