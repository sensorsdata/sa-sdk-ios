//
// NSString+SAHashCode.m
// SensorsAnalyticsSDK
//
// Created by 王灼洲 on 2017/7/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "NSString+SAHashCode.h"

@implementation NSString (HashCode)

- (int)sensorsdata_hashCode {
    int hashCode = 0;
    NSUInteger length = [self length];
    if (length == 0) {
        return hashCode;
    }
    for (NSUInteger i = 0; i < length; i++) {
        unichar character = [self characterAtIndex:i];
        hashCode = hashCode * 31 + (int)character;
    }
    return hashCode;
}

@end
