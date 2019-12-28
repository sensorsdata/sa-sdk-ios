//
//  SALocationManager.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/5/7.
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

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@interface SAGPSLocationConfig : NSObject
@property (nonatomic, assign) BOOL enableGPSLocation; //default is NO .
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;//default is kCLLocationCoordinate2DInvalid
@end;

@interface SALocationManager : NSObject {
    CLLocationManager *_locationManager;
}
@property (nonatomic, copy) void(^updateLocationBlock)(CLLocation *location, NSError *error);
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end
#endif
