//
// SADateFormatter.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2019/12/23.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
