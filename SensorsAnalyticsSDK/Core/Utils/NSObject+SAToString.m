//
// NSObject+SAToString.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/11/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "NSObject+SAToString.h"
#import "SADateFormatter.h"

@implementation NSObject (SAToString)

- (NSString *)sensorsdata_toString {
    if ([self isKindOfClass:[NSString class]]) {
        return (NSString *)self;
    }
    if ([self isKindOfClass:[NSDate class]]) {
        NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:kSAEventDateFormatter];
        return [dateFormatter stringFromDate:(NSDate *)self];
    }
    return self.description;
}

@end
