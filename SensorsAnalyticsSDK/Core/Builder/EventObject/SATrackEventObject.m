//
// SATrackEventObject.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/6.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SATrackEventObject.h"
#import "SAConstants+Private.h"
#import "SAPresetProperty.h"
#import "SAValidator.h"
#import "SALog.h"

static NSSet *presetEventNames;

@implementation SATrackEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super init];
    if (self) {
        self.eventId = eventId;
    }
    return self;
}

- (void)validateEventWithError:(NSError **)error {
    if (self.eventId && ![self.eventId isKindOfClass:NSString.class]) {
        *error = SAPropertyError(20000, @"Event name must be NSString. got: %@ %@", [self.eventId class], self.eventId);
        return;
    }
    if (self.eventId == nil || [self.eventId length] == 0) {
        *error = SAPropertyError(20001, @"Event name should not be empty or nil");
        return;
    }
    if (![SAValidator isValidKey:self.eventId]) {
        *error = SAPropertyError(20002, @"Event name[%@] not valid", self.eventId);
        return;
    }
}

#pragma makr - SAEventBuildStrategy
- (void)addEventProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)addLatestUtmProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)addModuleProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)addSuperProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
    // 从公共属性中更新 lib 节点中的 $app_version 值
    id appVersion = properties[kSAEventPresetPropertyAppVersion];
    if (appVersion) {
        self.lib.appVersion = appVersion;
    }
}

- (void)addCustomProperties:(NSDictionary *)properties error:(NSError **)error {
    [super addCustomProperties:properties error:error];
    if (*error) {
        return;
    }
    
    // 如果传入自定义属性中的 $lib_method 为 String 类型，需要进行修正处理
    id libMethod = self.properties[kSAEventPresetPropertyLibMethod];
    if (!libMethod || [libMethod isKindOfClass:NSString.class]) {
        if (![libMethod isEqualToString:kSALibMethodCode] &&
            ![libMethod isEqualToString:kSALibMethodAuto]) {
            libMethod = kSALibMethodCode;
        }
    }
    self.properties[kSAEventPresetPropertyLibMethod] = libMethod;
    self.lib.method = libMethod;
}

- (void)addReferrerTitleProperty:(NSString *)referrerTitle {
    self.properties[kSAEeventPropertyReferrerTitle] = referrerTitle;
}

- (void)addDurationProperty:(NSNumber *)duration {
    if (duration) {
        self.properties[@"event_duration"] = duration;
    }
}

@end

@implementation SASignUpEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = kSAEventTypeSignup;
    }
    return self;
}

- (NSMutableDictionary *)jsonObject {
    NSMutableDictionary *jsonObject = [super jsonObject];
    jsonObject[@"original_id"] = self.originalId;
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

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (void)addChannelProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)validateEventWithError:(NSError **)error {
    [super validateEventWithError:error];
    if (*error) {
        return;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        presetEventNames = [NSSet setWithObjects:
                            kSAEventNameAppStart,
                            kSAEventNameAppStartPassively ,
                            kSAEventNameAppEnd,
                            kSAEventNameAppViewScreen,
                            kSAEventNameAppClick,
                            kSAEventNameSignUp,
                            kSAEventNameAppCrashed,
                            kSAEventNameAppRemoteConfigChanged, nil];
    });
    //事件校验，预置事件提醒
    if ([presetEventNames containsObject:self.eventId]) {
        SALogWarn(@"\n【event warning】\n %@ is a preset event name of us, it is recommended that you use a new one", self.eventId);
    }
}

@end

@implementation SAAutoTrackEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (void)addCustomProperties:(NSDictionary *)properties error:(NSError **)error {
    [super addCustomProperties:properties error:error];
    if (*error) {
        return;
    }
    self.properties[kSAEventPresetPropertyLibMethod] = kSALibMethodAuto;
    self.lib.method = kSALibMethodAuto;

    // 不考虑 $AppClick 或者 $AppViewScreen 的计时采集，所以这里的 event 不会出现是 trackTimerStart 返回值的情况
    // 仅在全埋点的元素点击和页面浏览事件中添加 $lib_detail
    BOOL isAppClick = [self.eventId isEqualToString:kSAEventNameAppClick];
    BOOL isViewScreen = [self.eventId isEqualToString:kSAEventNameAppViewScreen];
    if (isAppClick || isViewScreen) {
        self.lib.detail = [NSString stringWithFormat:@"%@######", properties[kSAEventPropertyScreenName] ?: @""];
    }
}

@end

@implementation SAPresetEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

@end
