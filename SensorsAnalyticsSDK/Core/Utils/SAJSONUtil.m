//
//  SAJSONUtil.m
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/7.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SAJSONUtil.h"
#import "SALog.h"
#import "SADateFormatter.h"
#import "SAValidator.h"

@implementation SAJSONUtil

/**
 *  @abstract
 *  把一个Object转成Json字符串
 *
 *  @param obj 要转化的对象Object
 *
 *  @return 转化后得到的字符串
 */
+ (NSData *)JSONSerializeObject:(id)obj {
    id coercedObj = [self JSONObjectWithObject:obj];
    NSError *error = nil;
    NSData *data = nil;
    if (![NSJSONSerialization isValidJSONObject:coercedObj]) {
        return data;
    }
    @try {
        data = [NSJSONSerialization dataWithJSONObject:coercedObj options:0 error:&error];
    }
    @catch (NSException *exception) {
        SALogError(@"%@ exception encoding api data: %@", self, exception);
    }
    if (error) {
        SALogError(@"%@ error encoding api data: %@", self, error);
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
+ (id)JSONObjectWithObject:(id)obj {
    id newObj = [obj copy];
    // valid json types
    if ([newObj isKindOfClass:[NSString class]]) {
        return newObj;
    }
    //防止 float 精度丢失
    if ([newObj isKindOfClass:[NSNumber class]]) {
        if ([newObj stringValue] && [[newObj stringValue] rangeOfString:@"."].location != NSNotFound) {
            return [NSDecimalNumber decimalNumberWithDecimal:((NSNumber *)newObj).decimalValue];
        } else {
            return newObj;
        }
    }

    // recurse on containers
    if ([newObj isKindOfClass:[NSArray class]] || [newObj isKindOfClass:[NSSet class]]) {
        NSMutableArray *mutableArray = [NSMutableArray array];
        for (id value in newObj) {
            [mutableArray addObject:[self JSONObjectWithObject:value]];
        }
        return [NSArray arrayWithArray:mutableArray];
    }
    if ([newObj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mutableDic = [NSMutableDictionary dictionary];
        [(NSDictionary *)newObj enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *stringKey = key;
            if (![key isKindOfClass:[NSString class]]) {
                stringKey = [key description];
                SALogWarn(@"property keys should be strings. but property: %@, type: %@, key: %@", newObj, [key class], key);
            }
            mutableDic[stringKey] = [self JSONObjectWithObject:obj];
        }];
        return [NSDictionary dictionaryWithDictionary:mutableDic];
    }
    // some common cases
    if ([newObj isKindOfClass:[NSDate class]]) {
        NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:kSAEventDateFormatter];
        return [dateFormatter stringFromDate:newObj];
    }
    if ([newObj isKindOfClass:[NSNull class]]) {
        return [newObj description];
    }
    // default to sending the object's description
    SALogWarn(@"property values should be valid json types, but current value: %@, with invalid type: %@", newObj, [newObj class]);
    return [newObj description];
}

/**
 *  @abstract
 *  把 JSON 字符串转成对象 Object
 *
 *  @param jsonStr  要转化的字符串
 *
 *  @return 转化后得到的对象 Object
 */
+ (id)objectFromJSONString:(NSString *)jsonStr {
    if (![SAValidator isValidString:jsonStr]) {
        return nil;
    }
    NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

@end
