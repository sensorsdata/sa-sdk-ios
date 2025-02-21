//
// SARemoteConfigEventObject.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/6/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SARemoteConfigEventObject.h"

@implementation SARemoteConfigEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.ignoreRemoteConfig = YES;
    }
    return self;
}

@end
