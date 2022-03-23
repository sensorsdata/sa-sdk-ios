//
// SADateFormatter.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2019/12/23.
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

#import "SADateFormatter.h"

NSString * const kSAEventDateFormatter = @"yyyy-MM-dd HH:mm:ss.SSS";

@implementation SADateFormatter

+ (NSDateFormatter *)dateFormatterFromString:(NSString *)string {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    });
    if (dateFormatter) {
        [dateFormatter setDateFormat:string];
    }
    return dateFormatter;
}

@end
