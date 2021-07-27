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

+ (NSData *)dataWithJSONObject:(id)obj {
    id coercedObj = [self JSONSerializableObject:obj];

    if (![NSJSONSerialization isValidJSONObject:coercedObj]) {
        SALogError(@"%@ obj is not valid JSON: %@", self, coercedObj);
        return nil;
    }

    NSData *data = nil;
    @try {
        NSError *error = nil;
        data = [NSJSONSerialization dataWithJSONObject:coercedObj options:0 error:&error];
        if (error) {
            SALogError(@"%@ error encoding api data: %@", self, error);
        }
    }
    @catch (NSException *exception) {
        SALogError(@"%@ exception encoding api data: %@", self, exception);
    }
    return data;
}

+ (NSString *)stringWithJSONObject:(id)obj {
    NSData *jsonData = [self dataWithJSONObject:obj];
    if (![SAValidator isValidData:jsonData]) {
        SALogWarn(@"json data is invalid");
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/// 在Json序列化的过程中，对一些不同的类型做一些相应的转换
/// @param obj 要处理的对象 Object
/// @return 序列化后的 jsonString
+ (id)JSONSerializableObject:(id)obj {
    // 剔除 null 非法数据
    if ([obj isKindOfClass:[NSNull class]]) {
        return nil;
    }
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
            id newValue = [self JSONSerializableObject:value];
            if (newValue) {
                [mutableArray addObject:newValue];
            }
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
            mutableDic[stringKey] = [self JSONSerializableObject:obj];
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

+ (id)JSONObjectWithData:(NSData *)data {
    if (![SAValidator isValidData:data]) {
        SALogWarn(@"json data is invalid");
        return nil;
    }
    return [self JSONObjectWithData:data options:0];
}

+ (id)JSONObjectWithString:(NSString *)string {
    return [self JSONObjectWithString:string options:0];
}

+ (id)JSONObjectWithString:(NSString *)string options:(NSJSONReadingOptions)options {
    if (![SAValidator isValidString:string]) {
        SALogWarn(@"string verify failure: %@", string);
        return nil;
    }
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        SALogError(@"string dataUsingEncoding failure: %@",string);
        return nil;
    }
    return [self JSONObjectWithData:data options:options];
}

+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)options {
    id jsonObject = nil;
    @try {
        NSError *jsonError = nil;
        jsonObject = [NSJSONSerialization JSONObjectWithData:data options:options error:&jsonError];
        if (jsonError) {
            SALogError(@"json serialization error: %@",jsonError);
        }
    } @catch (NSException *exception) {
        SALogError(@"%@", exception);
    } @finally {
        return jsonObject;
    }
}

@end
