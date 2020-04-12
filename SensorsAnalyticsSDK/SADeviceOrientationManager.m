//
//  SADeviceOrientationManager.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/5/21.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION

#import "SALog.h"
#import "SADeviceOrientationManager.h"

static NSTimeInterval  kSADefaultDeviceMotionUpdateInterval = 0.5;

@implementation SADeviceOrientationConfig
- (instancetype)init{
    if (self = [super init]) {
        self.enableTrackScreenOrientation = NO;
        self.deviceOrientation = @"";
    }
    return self;
}
@end
@interface SADeviceOrientationManager()
@property (nonatomic, strong) CMMotionManager *cmmotionManager;
@property (nonatomic, strong) NSOperationQueue *updateQueue;
@end
@implementation SADeviceOrientationManager
- (instancetype)init {
    if (self = [super init]) {
        @try {
            self.cmmotionManager = [[CMMotionManager alloc] init];
            self.cmmotionManager.deviceMotionUpdateInterval = kSADefaultDeviceMotionUpdateInterval;
            self.updateQueue = [[NSOperationQueue alloc] init];
            self.updateQueue.name = @"com.sensorsdata.analytics.deviceMotionUpdatesQueue";
        } @catch (NSException *e) {
             SALogError(@"%@: %@", self, e);
            return nil;
        }
    }
    return self;
}

- (void) startDeviceMotionUpdates {
    @try {
        if (self.cmmotionManager.isDeviceMotionAvailable && !self.cmmotionManager.isDeviceMotionActive) {
            [self.cmmotionManager startDeviceMotionUpdatesToQueue:self.updateQueue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
                [self handleDeviceMotion:motion];
            }];
        }
    } @catch (NSException *e) {
        SALogError(@"%@: %@", self, e);
    }
}

- (void)stopDeviceMotionUpdates {
    @try {
        if (self.cmmotionManager.isDeviceMotionActive) {
            [self.cmmotionManager stopDeviceMotionUpdates];
        }
    } @catch (NSException *e) {
        SALogError(@"%@: %@", self, e);
    }
}

- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion {
    @try {
        double x = deviceMotion.gravity.x;
        double y = deviceMotion.gravity.y;
        if (fabs(y)  >= fabs(x)) {
            //y>0  UIDeviceOrientationPortraitUpsideDown;
            //y<0  UIDeviceOrientationPortrait;
            if (self.deviceOrientationBlock) {
                self.deviceOrientationBlock(@"portrait");
            }
        } else if (fabs(x) >= fabs(y)) {
            //x>0  UIDeviceOrientationLandscapeRight;
            //x<0  UIDeviceOrientationLandscapeLeft;
            if (self.deviceOrientationBlock) {
                self.deviceOrientationBlock(@"landscape");
            }
        }
    } @catch (NSException * e) {
        SALogError(@"%@: %@", self, e);
    }
}

- (void)dealloc {
    @try {
        [self stopDeviceMotionUpdates];
        [self.updateQueue cancelAllOperations];
        [self.updateQueue waitUntilAllOperationsAreFinished];
        self.updateQueue = nil;
        self.cmmotionManager = nil;
        self.deviceOrientationBlock = nil;
    } @catch (NSException *e) {
        SALogError(@"%@: %@", self, e);
    }
}

@end
#endif
