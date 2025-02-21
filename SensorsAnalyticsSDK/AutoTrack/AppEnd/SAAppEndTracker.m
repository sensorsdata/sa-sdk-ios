//
// SAAppEndTracker.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/2.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAppEndTracker.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"

@interface SAAppEndTracker ()

@property (nonatomic, copy) NSString *timerEventID;

@end

@implementation SAAppEndTracker

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _timerEventID = kSAEventNameAppEnd;
    }
    return self;
}

#pragma mark - Override

- (NSString *)eventId {
    return self.timerEventID ?: kSAEventNameAppEnd;
}

#pragma mark - Public Methods

- (void)autoTrackEvent {
    if (self.isIgnored) {
        return;
    }

    [self trackAutoTrackEventWithProperties:nil];
}

- (void)trackTimerStartAppEnd {
    self.timerEventID = [SensorsAnalyticsSDK.sdkInstance trackTimerStart:kSAEventNameAppEnd];
}

@end
