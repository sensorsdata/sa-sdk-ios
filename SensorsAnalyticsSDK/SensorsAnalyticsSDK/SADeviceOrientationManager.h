//
//  SADeviceOrientationManager.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/5/21.
//  Copyright © 2018年 SensorsData. All rights reserved.
//
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
@interface SADeviceOrientationConfig:NSObject
@property (nonatomic,strong) NSString *deviceOrientation;
@property (nonatomic,assign) BOOL enableTrackScreenOrientation;//default is NO
@end

@interface SADeviceOrientationManager : NSObject
@property (nonatomic,strong) void(^deviceOrientationBlock)(NSString * deviceOrientation);
- (void)startDeviceMotionUpdates;
- (void)stopDeviceMotionUpdates;
@end
#endif
