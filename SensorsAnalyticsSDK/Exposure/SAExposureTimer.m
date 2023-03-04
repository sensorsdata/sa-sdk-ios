//
// SAExposureTimer.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/10.
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

#import "SAExposureTimer.h"

@interface SAExposureTimer ()

@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) BOOL isCountingdown;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) dispatch_source_t source;

@end

@implementation SAExposureTimer

- (instancetype)initWithDuration:(NSTimeInterval)duration completeBlock:(nullable void (^)(void))completeBlock {
    self = [super init];
    if (self) {
        _duration = duration;
        _completeBlock = completeBlock;
        _isCountingdown = NO;
        NSString *queueLabel = [NSString stringWithFormat:@"cn.SensorsFocus.TimerQueue.%p", self];
        _queue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)start {
    if (self.isCountingdown) {
        return;
    }
    if (!self.source) {
        [self createTimer];
    } else {
        [self releaseTimer];
    }

    dispatch_resume(self.source);
    self.isCountingdown = YES;
}

- (void)stop {
    self.isCountingdown = NO;
    [self releaseTimer];
}

- (void)fire {
    if (self.completeBlock) {
        self.completeBlock();
    }
}

- (void)invalidate {
    [self stop];
}

- (void)releaseTimer {
    if (self.source) {
        dispatch_source_cancel(self.source);
        self.source = nil;
    }
}

- (void)createTimer {
    __weak typeof(self) weakSelf = self;
    self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.queue);
    dispatch_source_set_timer(_source, dispatch_time(DISPATCH_TIME_NOW, self.duration * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);
    dispatch_source_set_event_handler(_source, ^{
        [weakSelf fire];
    });
}

- (void)dealloc {
    [self invalidate];
}

@end
