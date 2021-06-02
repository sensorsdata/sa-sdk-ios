//
// SAAppEndTracker.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/2.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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
    return self.timerEventID;
}

#pragma mark - Public Methods

- (void)autoTrackEvent {
    if (self.isIgnored) {
        return;
    }

    [self trackAutoTrackEventWithProperties:nil];
}

- (void)trackTimerStartAppEnd {
    self.timerEventID = [SensorsAnalyticsSDK.sharedInstance trackTimerStart:kSAEventNameAppEnd];
}

@end
