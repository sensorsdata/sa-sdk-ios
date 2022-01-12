//
// SAValidator.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/2/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
#import "SensorsAnalyticsSDK+Private.h"

static NSRegularExpression *regexForValidKey;
static NSString *const kSAProperNameValidateRegularExpression = @"^((?!^distinct_id$|^original_id$|^time$|^properties$|^id$|^first_id$|^second_id$|^users$|^events$|^event$|^user_id$|^date$|^datetime$|^user_tag.*|^user_group.*)[a-zA-Z_$][a-zA-Z\\d_$]*)$";


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

+ (void)validKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    if (!key) {
        *error = SAPropertyError(SAValidatorErrorNil, @"Property key or Event name should not be nil");
        return;
    }

    if (![key isKindOfClass:[NSString class]]) {
        *error = SAPropertyError(SAValidatorErrorNotString, @"Property key or Event name must be string, not %@", [key class]);
        return;
    }

    if (key.length == 0) {
        *error = SAPropertyError(SAValidatorErrorEmpty, @"Property key or Event name is empty");
        return;
    }

    NSError *tempError = nil;
    [self reservedKeywordCheckForObject:key error:&tempError];
    if (tempError) {
        *error = tempError;
        return;
    }
    
    if (key.length > kSAEventNameMaxLength) {
        *error = SAPropertyError(SAValidatorErrorOverflow, @"Property key or Event name %@'s length is longer than %ld", key, kSAEventNameMaxLength);
        return;
    }
    *error = nil;
}

+ (void)reservedKeywordCheckForObject:(NSString *)object error:(NSError *__autoreleasing  _Nullable *)error {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regexForValidKey = [NSRegularExpression regularExpressionWithPattern:kSAProperNameValidateRegularExpression options:NSRegularExpressionCaseInsensitive error:nil];
    });

    if (!regexForValidKey) {
        *error = SAPropertyError(SAValidatorErrorRegexInit, @"Property Key validate regular expression init failed, please check the regular expression's syntax");
        return;
    }

    // 属性名通过正则表达式匹配，比使用谓词效率更高
    NSRange range = NSMakeRange(0, object.length);
    if ([regexForValidKey numberOfMatchesInString:object options:0 range:range] < 1) {
        *error = SAPropertyError(SAValidatorErrorInvalid, @"Property Key or Event name: [%@] is invalid.", object);
        return;
    }
}
@end
