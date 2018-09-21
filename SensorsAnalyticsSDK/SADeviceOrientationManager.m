//
//  SADeviceOrientationManager.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/5/21.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION

#import "SALogger.h"
#import "SADeviceOrientationManager.h"

static NSTimeInterval  kSADefaultDeviceMotionUpdateInterval = 0.5;

@implementation SADeviceOrientationConfig
-(instancetype)init{
    if (self = [super init]) {
        self.enableTrackScreenOrientation = NO;
        self.deviceOrientation = @"";
    }
    return self;
}
@end
@interface SADeviceOrientationManager()
@property(nonatomic,strong)CMMotionManager *cmmotionManager;
@property(nonatomic,strong)NSOperationQueue *updateQueue;
@end
@implementation SADeviceOrientationManager
- (instancetype)init {
    if (self = [super init]) {
        @try {
            self.cmmotionManager = [[CMMotionManager alloc]init];
            self.cmmotionManager.deviceMotionUpdateInterval = kSADefaultDeviceMotionUpdateInterval;
            self.updateQueue = [[NSOperationQueue alloc]init];
            self.updateQueue.name = @"com.sensorsdata.analytics.deviceMotionUpdatesQueue";
        } @catch (NSException *e) {
             SAError(@"%@: %@", self, e);
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
        SAError(@"%@: %@", self, e);
    }
}

- (void)stopDeviceMotionUpdates {
    @try {
        if (self.cmmotionManager.isDeviceMotionActive) {
            [self.cmmotionManager stopDeviceMotionUpdates];
        }
    } @catch (NSException *e) {
        SAError(@"%@: %@", self, e);
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
        SAError(@"%@: %@", self, e);
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
        SAError(@"%@: %@", self, e);
    }
}

@end
#endif
