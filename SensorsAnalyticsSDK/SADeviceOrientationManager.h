//
//  SADeviceOrientationManager.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/5/21.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
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

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
@interface SADeviceOrientationConfig : NSObject
@property (nonatomic, strong) NSString *deviceOrientation;
@property (nonatomic, assign) BOOL enableTrackScreenOrientation;//default is NO
@end

@interface SADeviceOrientationManager : NSObject
@property (nonatomic, strong) void(^deviceOrientationBlock)(NSString * deviceOrientation);
- (void)startDeviceMotionUpdates;
- (void)stopDeviceMotionUpdates;
@end
#endif
