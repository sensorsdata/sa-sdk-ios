//
// SAPropertyValidator.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/12.
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

#import "SAPropertyValidator.h"
#import "SAConstants+Private.h"
#import "SACommonUtility.h"
#import "SADateFormatter.h"
#import "SAValidator.h"

static NSUInteger const kSAPropertyLengthLimitation = 8191;

@implementation NSString (SAProperty)

- (void)sensorsdata_isValidPropertyKeyWithError:(NSError *__autoreleasing  _Nullable *)error {
    if (![SAValidator isValidKey: self]) {
        *error = SAPropertyError(10001, @"property name[%@] is not valid", self);
    }
}

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    NSInteger maxLength = kSAPropertyLengthLimitation;
    if ([key isEqualToString:@"app_crashed_reason"]) {
        maxLength = kSAPropertyLengthLimitation * 2;
    }
    NSUInteger length = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (length > maxLength) {
        //截取再拼接 $ 末尾，替换原数据
        NSMutableString *newString = [NSMutableString stringWithString:[SACommonUtility subByteString:self byteLength:maxLength - 1]];
        [newString appendString:@"$"];
        return [newString copy];
    }
    return self;
}

@end

@implementation NSNumber (SAProperty)

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    return self;
}

@end

@implementation NSDate (SAProperty)

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    return self;
}

@end

@implementation NSSet (SAProperty)

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    NSMutableSet *result = [NSMutableSet set];
    for (id element in self) {
        if (![element isKindOfClass:NSString.class]) {
            *error = SAPropertyError(10002, @"%@ value of NSSet, NSArray must be NSString. got: %@ %@", self, [element class], element);
            return nil;
        }
        id sensorsValue = [(id <SAPropertyValueProtocol>)element sensorsdata_propertyValueWithKey:key error:error];
        [result addObject:sensorsValue];
    }
    return [result copy];
}

@end

@implementation NSArray (SAProperty)

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    NSMutableArray *result = [NSMutableArray array];
    for (id element in self) {
        if (![element isKindOfClass:NSString.class]) {
            *error = SAPropertyError(10003, @"%@ value of NSSet, NSArray must be NSString. got: %@ %@", self, [element class], element);
            return nil;
        }
        id sensorsValue = [(id <SAPropertyValueProtocol>)element sensorsdata_propertyValueWithKey:key error:error];
        [result addObject:sensorsValue];
    }
    return [result copy];
}

@end

@implementation NSNull (SAProperty)

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    return nil;
}

@end

@implementation NSDictionary (SAProperty)

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

@implementation SAPropertyValidator

+ (NSMutableDictionary *)validProperties:(NSDictionary *)properties error:(NSError **)error {
    return [self validProperties:properties validator:properties error:error];
}

+ (NSMutableDictionary *)validProperties:(NSDictionary *)properties validator:(id<SAEventPropertyValidatorProtocol>)validator error:(NSError **)error {
    if (![properties isKindOfClass:[NSDictionary class]] || ![validator conformsToProtocol:@protocol(SAEventPropertyValidatorProtocol)]) {
        return nil;
    }
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (id key in properties) {
        id value = [validator sensorsdata_validKey:key value:properties[key] error:error];
        if (*error) {
            return nil;
        }

        result[key] = value;
    }
    return result;
}

@end

