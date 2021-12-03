//
// SAValidator.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/2/19.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAValidator.h"
#import "SAConstants+Private.h"
#import "SALog.h"

static NSRegularExpression *regexForValidKey;

@implementation SAValidator

+ (BOOL)isValidString:(NSString *)string {
    return ([string isKindOfClass:[NSString class]] && ([string length] > 0));
}

+ (BOOL)isValidArray:(NSArray *)array {
    return ([array isKindOfClass:[NSArray class]] && ([array count] > 0));
}

+ (BOOL)isValidDictionary:(NSDictionary *)dictionary {
    return ([dictionary isKindOfClass:[NSDictionary class]] && ([dictionary count] > 0));
}

+ (BOOL)isValidData:(NSData *)data {
    return ([data isKindOfClass:[NSData class]] && ([data length] > 0));
}

+ (BOOL)isValidKey:(NSString *)key {
    if (![self isValidString:key]) {
        return NO;
    }
    @try {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *name = @"^((?!^user_group|^user_tag)[a-zA-Z_$][a-zA-Z\\d_$]{0,99})$";
            regexForValidKey = [NSRegularExpression regularExpressionWithPattern:name options:NSRegularExpressionCaseInsensitive error:nil];
        });
        // 保留字段通过字符串直接比较，效率更高
        NSSet *reservedProperties = sensorsdata_reserved_properties();
        for (NSString *reservedProperty in reservedProperties) {
            if ([reservedProperty caseInsensitiveCompare:key] == NSOrderedSame) {
                return NO;
            }
        }
        // 属性名通过正则表达式匹配，比使用谓词效率更高
        NSRange range = NSMakeRange(0, key.length);
        return ([regexForValidKey numberOfMatchesInString:key options:0 range:range] > 0);
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
        return NO;
    }
}

@end
