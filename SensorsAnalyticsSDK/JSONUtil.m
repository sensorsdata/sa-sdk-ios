//
//  JSONUtil.m
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/7.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "JSONUtil.h"
#import "SALogger.h"

@implementation JSONUtil {
    NSDateFormatter *_dateFormatter;
}

- (id)init {
    self = [super init];
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC+8"]];
    return self;
}

/**
 *  @abstract
 *  把一个Object转成Json字符串
 *
 *  @param obj 要转化的对象Object
 *
 *  @return 转化后得到的字符串
 */
- (NSData *)JSONSerializeObject:(id)obj {
    id coercedObj = [self JSONSerializableObjectForObject:obj];
    NSError *error = nil;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:coercedObj options:0 error:&error];
    }
    @catch (NSException *exception) {
        SAError(@"%@ exception encoding api data: %@", self, exception);
    }
    if (error) {
        SAError(@"%@ error encoding api data: %@", self, error);
    }
    return data;
}

/**
 *  @abstract
 *  在Json序列化的过程中，对一些不同的类型做一些相应的转换
 *
 *  @param obj 要处理的对象Object
 *
 *  @return 处理后的对象Object
 */
- (id)JSONSerializableObjectForObject:(id)obj {
    id newObj = [obj copy];
    // valid json types
    if ([newObj isKindOfClass:[NSString class]]) {
        return newObj;
    }
    //防止 float 精度丢失
    if ([newObj isKindOfClass:[NSNumber class]]) {
        @try {
            if ([newObj stringValue] && [[obj stringValue] rangeOfString:@"."].location != NSNotFound) {
                return [NSDecimalNumber decimalNumberWithDecimal:((NSNumber *)obj).decimalValue];
            } else {
                return newObj;
            }
        } @catch (NSException *exception) {
            return newObj;
        }
    }
    
    // recurse on containers
    if ([newObj isKindOfClass:[NSArray class]]) {
        NSMutableArray *a = [NSMutableArray array];
        for (id i in newObj) {
            [a addObject:[self JSONSerializableObjectForObject:i]];
        }
        return [NSArray arrayWithArray:a];
    }
    if ([newObj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (id key in newObj) {
            NSString *stringKey;
            if (![key isKindOfClass:[NSString class]]) {
                stringKey = [key description];
                SAError(@"%@ warning: property keys should be strings. got: %@. coercing to: %@", self, [key class], stringKey);
            } else {
                stringKey = [NSString stringWithString:key];
            }
            id v = [self JSONSerializableObjectForObject:obj[key]];
            d[stringKey] = v;
        }
        return [NSDictionary dictionaryWithDictionary:d];
    }
    if ([newObj isKindOfClass:[NSSet class]]) {
        NSMutableArray *a = [NSMutableArray array];
        for (id i in newObj) {
            [a addObject:[self JSONSerializableObjectForObject:i]];
        }
        return [NSArray arrayWithArray:a];
    }
    // some common cases
    if ([newObj isKindOfClass:[NSDate class]]) {
        return [_dateFormatter stringFromDate:newObj];
    }
    // default to sending the object's description
    NSString *s = [newObj description];
    SAError(@"%@ warning: property values should be valid json types. got: %@. coercing to: %@", self, [newObj class], s);
    return s;
}

@end
