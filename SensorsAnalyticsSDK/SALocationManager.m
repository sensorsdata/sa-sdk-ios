//
//  SALocationManager.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/5/7.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
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


#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS

#import "SALocationManager.h"
#import "SALog.h"
#define kSADefaultDistanceFilter 100.0
#define kSADefaultDesiredAccuracy kCLLocationAccuracyHundredMeters
@implementation SAGPSLocationConfig
- (instancetype)init {
    if (self = [super init]) {
        self.enableGPSLocation = NO;
        self.coordinate = kCLLocationCoordinate2DInvalid;
    }
    return self;
}
@end
@interface SALocationManager() <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isUpdatingLocation;
@end
@implementation SALocationManager
- (instancetype)init {
    if (self = [super init]) {
        //默认设置设置精度为 100 ,也就是 100 米定位一次 ；准确性 kCLLocationAccuracyHundredMeters
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kSADefaultDesiredAccuracy;
        self.locationManager.distanceFilter = kSADefaultDistanceFilter;
        self.isUpdatingLocation = NO;
    }
    return self;
}

- (void)startUpdatingLocation {
    @try {
        //判断当前设备定位服务是否打开
        if (![CLLocationManager locationServicesEnabled]) {
            SALogWarn(@"设备尚未打开定位服务");
            return;
        }
        if (@available(iOS 8.0, *)) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        if (_isUpdatingLocation == NO) {
            [self.locationManager startUpdatingLocation];
            _isUpdatingLocation = YES;
        }
    }@catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)stopUpdatingLocation {
    @try {
        if (_isUpdatingLocation) {
            [self.locationManager stopUpdatingLocation];
            _isUpdatingLocation = NO;
        }
    }@catch (NSException *e) {
       SALogError(@"%@ error: %@", self, e);
    }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations API_AVAILABLE(ios(6.0), macos(10.9)) {
    @try {
        if (self.updateLocationBlock) {
            self.updateLocationBlock(locations.lastObject, nil);
        }
    }@catch (NSException * e) {
         SALogError(@"%@ error: %@", self, e);
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    @try {
        if (self.updateLocationBlock) {
            self.updateLocationBlock(nil, error);
        }
    }@catch (NSException * e) {
         SALogError(@"%@ error: %@", self, e);
    }
}

@end
#endif
