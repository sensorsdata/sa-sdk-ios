//
// SAValidator.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define SAPropertyError(errorCode, fromat, ...) \
    [NSError errorWithDomain:@"SensorsAnalyticsErrorDomain" \
                        code:errorCode \
                    userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:fromat,##__VA_ARGS__]}] \


typedef NS_ENUM(NSUInteger, SAValidatorError) {
    SAValidatorErrorNil = 20001,
    SAValidatorErrorNotString,
    SAValidatorErrorEmpty,
    SAValidatorErrorRegexInit,
    SAValidatorErrorInvalid,
    SAValidatorErrorOverflow,
};

@interface SAValidator : NSObject

+ (BOOL)isValidString:(NSString *)string;

+ (BOOL)isValidDictionary:(NSDictionary *)dictionary;

+ (BOOL)isValidArray:(NSArray *)array;

+ (BOOL)isValidData:(NSData *)data;

/// 校验事件名或参数名是否有效
+ (void)validKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable * _Nullable)error;

//保留字校验
+ (void)reservedKeywordCheckForObject:(NSString *)object error:(NSError *__autoreleasing  _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
