//
// SAProfileEventObject.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/13.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAProfileEventObject.h"
#import "SAConstants+Private.h"

@implementation SAProfileEventObject

- (instancetype)initWithType:(NSString *)type {
    self = [super init];
    if (self) {
        self.type = [SABaseEventObject eventTypeWithType:type];
    }
    return self;
}

@end

@implementation SAProfileIncrementEventObject

- (id)sensorsdata_validKey:(NSString *)key value:(id)value error:(NSError *__autoreleasing  _Nullable *)error {
    id newValue = [super sensorsdata_validKey:key value:value error:error];
    if (![value isKindOfClass:[NSNumber class]]) {
        *error = SAPropertyError(10007, @"%@ profile_increment value must be NSNumber. got: %@ %@", self, [value class], value);
        return nil;
    }
    return newValue;
}

@end

@implementation SAProfileAppendEventObject

- (id)sensorsdata_validKey:(NSString *)key value:(id)value error:(NSError *__autoreleasing  _Nullable *)error {
    id newValue = [super sensorsdata_validKey:key value:value error:error];
    if (![newValue isKindOfClass:[NSArray class]] &&
        ![newValue isKindOfClass:[NSSet class]]) {
        *error = SAPropertyError(10006, @"%@ profile_append value must be NSSet, NSArray. got %@ %@", self, [value  class], value);
        return nil;
    }
    return newValue;
}

@end
