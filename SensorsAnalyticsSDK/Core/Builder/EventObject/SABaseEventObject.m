//
// SABaseEventObject.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/13.
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

#import "SABaseEventObject.h"
#import "SAConstants+Private.h"
#import "SAPresetProperty.h"
#import "SALog.h"

@implementation SABaseEventObject

- (instancetype)init {
    self = [super init];
    if (self) {
        _lib = [[SAEventLibObject alloc] init];
        _timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        _trackId = @(arc4random());
        _properties = [NSMutableDictionary dictionary];
        _currentSystemUpTime = NSProcessInfo.processInfo.systemUptime * 1000;
        
        _ignoreRemoteConfig = NO;
    }
    return self;
}

- (NSString *)event {
    if (![self.eventId hasSuffix:kSAEventIdSuffix]) {
        return self.eventId;
    }
    //eventId 结构为 {eventName}_D3AC265B_3CC2_4C45_B8F0_3E05A83A9DAE_SATimer，新增后缀长度为 44
    NSString *eventName = [self.eventId substringToIndex:(self.eventId.length - 1) - 44];
    return eventName;
}

- (BOOL)isSignUp {
    return NO;
}

- (void)validateEventWithError:(NSError **)error {
}

- (NSMutableDictionary *)jsonObject {
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    eventInfo[kSAEventProperties] = self.properties;
    eventInfo[kSAEventDistinctId] = self.distinctId;
    eventInfo[kSAEventLoginId] = self.loginId;
    eventInfo[kSAEventAnonymousId] = self.anonymousId;
    eventInfo[kSAEventType] = self.type;
    eventInfo[kSAEventTime] = @(self.timeStamp);
    eventInfo[kSAEventLib] = [self.lib jsonObject];
    eventInfo[kSAEventTrackId] = self.trackId;
    eventInfo[kSAEventName] = self.event;
    eventInfo[kSAEventProject] = self.project;
    eventInfo[kSAEventToken] = self.token;
    return eventInfo;
}

#pragma makr - SAEventBuildStrategy
- (void)addEventProperties:(NSDictionary *)properties {
}

- (void)addLatestUtmProperties:(NSDictionary *)properties {
}

- (void)addChannelProperties:(NSDictionary *)properties {
}

- (void)addModuleProperties:(NSDictionary *)properties {
}

- (void)addSuperProperties:(NSDictionary *)properties {
}

- (void)addCustomProperties:(NSDictionary *)properties error:(NSError **)error {
    NSMutableDictionary *props = [SAPropertyValidator validProperties:properties validator:self error:error];
    if (*error) {
        return;
    }

    [self.properties addEntriesFromDictionary:props];
    
    // 事件、公共属性和动态公共属性都需要支持修改 $project, $token, $time
    self.project = (NSString *)self.properties[kSAEventCommonOptionalPropertyProject];
    self.token = (NSString *)self.properties[kSAEventCommonOptionalPropertyToken];
    id originalTime = self.properties[kSAEventCommonOptionalPropertyTime];
    if ([originalTime isKindOfClass:NSDate.class]) {
        NSDate *customTime = (NSDate *)originalTime;
        int64_t customTimeInt = [customTime timeIntervalSince1970] * 1000;
        if (customTimeInt >= kSAEventCommonOptionalPropertyTimeInt) {
            self.timeStamp = customTimeInt;
        } else {
            SALogError(@"$time error %lld, Please check the value", customTimeInt);
        }
    } else if (originalTime) {
        SALogError(@"$time '%@' invalid, Please check the value", originalTime);
    }
    
    // $project, $token, $time 处理完毕后需要移除
    NSArray<NSString *> *needRemoveKeys = @[kSAEventCommonOptionalPropertyProject,
                                            kSAEventCommonOptionalPropertyToken,
                                            kSAEventCommonOptionalPropertyTime];
    [self.properties removeObjectsForKeys:needRemoveKeys];
}

- (void)addReferrerTitleProperty:(NSString *)referrerTitle {
}

- (void)addDurationProperty:(NSNumber *)duration {
}

- (void)correctDeviceID:(NSString *)deviceID {
    // 修正 $device_id
    // 1. 公共属性, 动态公共属性, 自定义属性不允许修改 $device_id
    // 2. trackEventCallback 可以修改 $device_id
    // 3. profile 操作中若传入 $device_id, 也需要进行修正
    if (self.properties[kSAEventPresetPropertyDeviceId] && deviceID) {
        self.properties[kSAEventPresetPropertyDeviceId] = deviceID;
    }
}

- (id)sensorsdata_validKey:(NSString *)key value:(id)value error:(NSError *__autoreleasing  _Nullable *)error {
    if (![key conformsToProtocol:@protocol(SAPropertyKeyProtocol)]) {
        *error = SAPropertyError(10004, @"Property Key should by %@", [key class]);
        return nil;
    }

    [(id <SAPropertyKeyProtocol>)key sensorsdata_isValidPropertyKeyWithError:error];
    if (*error) {
        return nil;
    }

    if (![value conformsToProtocol:@protocol(SAPropertyValueProtocol)]) {
        *error = SAPropertyError(10005, @"%@ property values must be NSString, NSNumber, NSSet, NSArray or NSDate. got: %@ %@", self, [value class], value);
        return nil;
    }

    // value 转换
    return [(id <SAPropertyValueProtocol>)value sensorsdata_propertyValueWithKey:key error:error];
}

@end
