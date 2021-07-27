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

#import <UIKit/UIKit.h>
#import "SALocationManager.h"
#import "SAConstants+Private.h"
#import "SALog.h"

static NSString * const kSAEventPresetPropertyLatitude = @"$latitude";
static NSString * const kSAEventPresetPropertyLongitude = @"$longitude";
static NSString * const kSAEventPresetPropertyCoordinateSystem = @"$geo_coordinate_system";
static NSString * const kSAAppleCoordinateSystem = @"WGS84";

@interface SALocationManager() <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isUpdatingLocation;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@end

@implementation SALocationManager

- (instancetype)init {
    if (self = [super init]) {
        //默认设置设置精度为 100 ,也就是 100 米定位一次 ；准确性 kCLLocationAccuracyHundredMeters
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _locationManager.distanceFilter = 100.0;

        _isUpdatingLocation = NO;

        _coordinate = kCLLocationCoordinate2DInvalid;

        [self setupListeners];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SALocationManagerProtocol

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        [self startUpdatingLocation];
    } else {
        [self stopUpdatingLocation];
    }
}

- (NSDictionary *)properties {
    if (!CLLocationCoordinate2DIsValid(self.coordinate)) {
        return nil;
    }
    NSInteger latitude = self.coordinate.latitude * pow(10, 6);
    NSInteger longitude = self.coordinate.longitude * pow(10, 6);
    return @{kSAEventPresetPropertyLatitude: @(latitude), kSAEventPresetPropertyLongitude: @(longitude), kSAEventPresetPropertyCoordinateSystem: kSAAppleCoordinateSystem};
}

#pragma mark - Listener

- (void)setupListeners {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(remoteConfigManagerModelChanged:)
                               name:SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION
                             object:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self stopUpdatingLocation];
}

- (void)remoteConfigManagerModelChanged:(NSNotification *)sender {
    BOOL disableSDK = NO;
    @try {
        disableSDK = [[sender.object valueForKey:@"disableSDK"] boolValue];
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
    if (disableSDK) {
        [self stopUpdatingLocation];
    } else if (self.enable) {
        [self startUpdatingLocation];
    }
}

#pragma mark - Public

- (void)startUpdatingLocation {
    @try {
        if (self.isUpdatingLocation) {
            return;
        }
        //判断当前设备定位服务是否打开
        if (![CLLocationManager locationServicesEnabled]) {
            SALogWarn(@"设备尚未打开定位服务");
            return;
        }

        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager startUpdatingLocation];
        self.isUpdatingLocation = YES;
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)stopUpdatingLocation {
    @try {
        if (self.isUpdatingLocation) {
            [self.locationManager stopUpdatingLocation];
            self.isUpdatingLocation = NO;
        }
    }@catch (NSException *e) {
       SALogError(@"%@ error: %@", self, e);
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations API_AVAILABLE(ios(6.0), macos(10.9)) {
    self.coordinate = locations.lastObject.coordinate;
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    SALogError(@"enableTrackGPSLocation error：%@", error);
}

@end
