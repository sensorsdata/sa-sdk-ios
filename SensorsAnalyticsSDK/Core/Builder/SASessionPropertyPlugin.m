//
// SASessionPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/5.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SASessionPropertyPlugin.h"
#import "SAPropertyPluginManager.h"
#import "SASessionProperty.h"

@interface SASessionPropertyPlugin()

@property (nonatomic, weak) SASessionProperty *sessionProperty;

@end

@implementation SASessionPropertyPlugin

- (instancetype)initWithSessionProperty:(SASessionProperty *)sessionProperty {
    NSAssert(sessionProperty, @"You must initialize sessionProperty");
    if (!sessionProperty) {
        return nil;
    }

    self = [super init];
    if (self) {
        _sessionProperty = sessionProperty;
    }
    return self;
}

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return kSAPropertyPluginPrioritySuper;
}

- (NSDictionary<NSString *,id> *)properties {
    if (!self.filter) {
        return nil;
    }
    NSDictionary *properties = [self.sessionProperty sessionPropertiesWithEventTime:@(self.filter.time)];
    return properties;
}

@end
