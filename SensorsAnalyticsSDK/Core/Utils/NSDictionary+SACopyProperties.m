//
// NSDictionary+CopyProperties.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/10/13.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "NSDictionary+SACopyProperties.h"
#import "SAPropertyValidator.h"
#import "SALog.h"

@implementation NSDictionary (SACopyProperties)

- (NSDictionary *)sensorsdata_deepCopy {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    NSArray *allKeys = [self allKeys];
    for (id key in allKeys) {
        if (![key conformsToProtocol:@protocol(SAPropertyKeyProtocol)]) {
            continue;
        }
        id value = [self objectForKey:key];
        if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSDate class]]) {
            properties[key] = [value copy];
            continue;
        }
        if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
            properties[key] = [self sensorsdata_copyArrayOrDictionary:value];
            continue;
        }
        if ([value isKindOfClass:[NSSet class]]) {
            NSSet *set = value;
            properties[key] = [self sensorsdata_copyArrayOrDictionary:[set allObjects]];
            continue;
        }
        properties[key] = value;
    }
    return [properties copy];
}

- (id)sensorsdata_copyArrayOrDictionary:(id)object {
    if (!object) {
        return nil;
    }
    if (![NSJSONSerialization isValidJSONObject:object]) {
        return nil;
    }
    @try {
        NSError *error;
        NSData *objectData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
        id tempObject = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingFragmentsAllowed error:&error];
        if (error) {
            SALogError(@"%@", error.localizedDescription);
            return nil;
        }
        return tempObject;
    } @catch (NSException *exception) {
        SALogError(@"%@", exception);
    }
}

@end
