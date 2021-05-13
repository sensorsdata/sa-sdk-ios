//
// SAProfileEventObject.m
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

#import "SAProfileEventObject.h"
#import "SAConstants+Private.h"

@implementation SAProfileEventObject

- (instancetype)initWithType:(NSString *)type {
    self = [super init];
    if (self) {
        self.type = type;
        self.lib.method = kSALibMethodCode;
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
