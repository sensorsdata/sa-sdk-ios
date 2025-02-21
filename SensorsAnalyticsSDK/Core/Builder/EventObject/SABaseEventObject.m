//
// SABaseEventObject.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/13.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SABaseEventObject.h"
#import "SAConstants+Private.h"
#import "SALog.h"

@implementation SABaseEventObject

- (instancetype)init {
    self = [super init];
    if (self) {
        _type = SAEventTypeTrack;
        _lib = [[SAEventLibObject alloc] init];
        _time = [[NSDate date] timeIntervalSince1970] * 1000;
        _trackId = @(arc4random());
        _properties = [NSMutableDictionary dictionary];
        _currentSystemUpTime = NSProcessInfo.processInfo.systemUptime * 1000;
        
        _ignoreRemoteConfig = NO;
        _hybridH5 = NO;
        _isInstantEvent = NO;
    }
    return self;
}

- (instancetype)initWithH5Event:(NSDictionary *)event {
    self = [super init];
    if (self) {
        NSString *type = event[kSAEventType];
        _type = [SABaseEventObject eventTypeWithType:type];
        _lib = [[SAEventLibObject alloc] initWithH5Lib:event[kSAEventLib]];
        _trackId = @(arc4random());
        _currentSystemUpTime = NSProcessInfo.processInfo.systemUptime * 1000;

        _ignoreRemoteConfig = NO;

        _hybridH5 = YES;

        // 优先使用 web 端时间，防止历史事件时间被改错
        if ([event[kSAEventTime] isKindOfClass:NSNumber.class]) {
            _time = [event[kSAEventTime] unsignedLongLongValue];
        } else {
            _time = [[NSDate date] timeIntervalSince1970] * 1000;
        }
        _eventId = event[kSAEventName];
        _loginId = event[kSAEventLoginId];
        _anonymousId = event[kSAEventAnonymousId];
        _distinctId = event[kSAEventDistinctId];
        _originalId = event[kSAEventOriginalId];
        _identities = event[kSAEventIdentities];
        NSMutableDictionary *properties = [event[kSAEventProperties] mutableCopy];
        [properties removeObjectForKey:@"_nocache"];

        _project = properties[kSAEventProject];
        _token = properties[kSAEventToken];

        id timeNumber = properties[kSAEventCommonOptionalPropertyTime];
        // $time 类型合法
        if ([timeNumber isKindOfClass:[NSNumber class]]) {
            NSNumber *customTime = timeNumber;

            if ([customTime compare:@(kSAEventCommonOptionalPropertyTimeInt)] == NSOrderedAscending) {
                SALogError(@"H5 $time error %@，Please check the value", timeNumber);
            } else {
                _time = [customTime unsignedLongLongValue];
            }
        } else if (timeNumber) {
            // $time 类型不合法
            SALogError(@"H5 $time '%@' invalid，Please check the value", timeNumber);
        }

        [properties removeObjectsForKeys:@[@"_nocache", @"server_url", kSAAppVisualProperties, kSAEventProject, kSAEventToken, kSAEventCommonOptionalPropertyTime]];
        _properties = properties;
        NSNumber *isInstantEvent = event[kSAInstantEventKey];
        if ([isInstantEvent isKindOfClass:[NSNumber class]]) {
            _isInstantEvent = [isInstantEvent boolValue];
        }
    }
    return self;
}

- (NSString *)event {
    if (![self.eventId isKindOfClass:[NSString class]]) {
        return nil;
    }
    if (![self.eventId hasSuffix:kSAEventIdSuffix]) {
        return self.eventId;
    }
    //eventId 结构为 {eventName}_D3AC265B_3CC2_4C45_B8F0_3E05A83A9DAE_SATimer，新增后缀长度为 44
    if (self.eventId.length < 45) {
        return nil;
    }
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
    eventInfo[kSAEventType] = [SABaseEventObject typeWithEventType:self.type];
    eventInfo[kSAEventTime] = @(self.time);
    eventInfo[kSAEventLib] = [self.lib jsonObject];
    eventInfo[kSAEventTrackId] = self.trackId;
    eventInfo[kSAEventName] = self.event;
    eventInfo[kSAEventProject] = self.project;
    eventInfo[kSAEventToken] = self.token;
    eventInfo[kSAEventIdentities] = self.identities;
    // App 内嵌 H5 事件标记
    eventInfo[kSAEventHybridH5] = self.hybridH5 ? @(self.hybridH5) : nil;
    return eventInfo;
}

- (id)sensorsdata_validKey:(NSString *)key value:(id)value error:(NSError *__autoreleasing  _Nullable *)error {
    if (![key conformsToProtocol:@protocol(SAPropertyKeyProtocol)]) {
        *error = SAPropertyError(10004, @"Property Key: %@ must be NSString", key);
        return nil;
    }

    // key 校验
    [(id <SAPropertyKeyProtocol>)key sensorsdata_isValidPropertyKeyWithError:error];
    if (*error && (*error).code != SAValidatorErrorOverflow) {
        return nil;
    }

    if (![value conformsToProtocol:@protocol(SAPropertyValueProtocol)]) {
        *error = SAPropertyError(10005, @"%@ property values must be NSString, NSNumber, NSSet, NSArray or NSDate. got: %@ %@", self, [value class], value);
        return nil;
    }

    // value 转换
    return [(id <SAPropertyValueProtocol>)value sensorsdata_propertyValueWithKey:key error:error];
}

+ (SAEventType)eventTypeWithType:(NSString *)type {
    if ([type isEqualToString:kSAEventTypeTrack]) {
        return SAEventTypeTrack;
    }
    if ([type isEqualToString:kSAEventTypeSignup]) {
        return SAEventTypeSignup;
    }
    if ([type isEqualToString:kSAEventTypeBind]) {
        return SAEventTypeBind;
    }
    if ([type isEqualToString:kSAEventTypeUnbind]) {
        return SAEventTypeUnbind;
    }
    if ([type isEqualToString:kSAProfileSet]) {
        return SAEventTypeProfileSet;
    }
    if ([type isEqualToString:kSAProfileSetOnce]) {
        return SAEventTypeProfileSetOnce;
    }
    if ([type isEqualToString:kSAProfileUnset]) {
        return SAEventTypeProfileUnset;
    }
    if ([type isEqualToString:kSAProfileDelete]) {
        return SAEventTypeProfileDelete;
    }
    if ([type isEqualToString:kSAProfileAppend]) {
        return SAEventTypeProfileAppend;
    }
    if ([type isEqualToString:kSAProfileIncrement]) {
        return SAEventTypeIncrement;
    }
    if ([type isEqualToString:kSAEventItemSet]) {
        return SAEventTypeItemSet;
    }
    if ([type isEqualToString:kSAEventItemDelete]) {
        return SAEventTypeItemDelete;
    }
    return SAEventTypeDefault;
}

+ (NSString *)typeWithEventType:(SAEventType)type {
    if (type & SAEventTypeTrack) {
        return kSAEventTypeTrack;
    }
    if (type & SAEventTypeSignup) {
        return kSAEventTypeSignup;
    }
    if (type & SAEventTypeProfileSet) {
        return kSAProfileSet;
    }
    if (type & SAEventTypeProfileSetOnce) {
        return kSAProfileSetOnce;
    }
    if (type & SAEventTypeProfileUnset) {
        return kSAProfileUnset;
    }
    if (type & SAEventTypeProfileDelete) {
        return kSAProfileDelete;
    }
    if (type & SAEventTypeProfileAppend) {
        return kSAProfileAppend;
    }
    if (type & SAEventTypeIncrement) {
        return kSAProfileIncrement;
    }
    if (type & SAEventTypeItemSet) {
        return kSAEventItemSet;
    }
    if (type & SAEventTypeItemDelete) {
        return kSAEventItemDelete;
    }
    if (type & SAEventTypeBind) {
        return kSAEventTypeBind;
    }
    if (type & SAEventTypeUnbind) {
        return kSAEventTypeUnbind;
    }

    return nil;
}

@end
