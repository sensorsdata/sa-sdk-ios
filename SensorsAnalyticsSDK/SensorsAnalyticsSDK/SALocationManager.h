//
//  SALocationManager.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/5/7.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@interface SAGPSLocationConfig:NSObject
@property (nonatomic,assign) BOOL enableGPSLocation; //default is NO .
@property (nonatomic,assign) CLLocationCoordinate2D coordinate;//default is kCLLocationCoordinate2DInvalid
@end;

@interface SALocationManager : NSObject {
    CLLocationManager *_locationManager;
}
@property(nonatomic,copy) void(^updateLocationBlock)(CLLocation *location,NSError *error);
-(void)startUpdatingLocation;
-(void)stopUpdatingLocation;

@end
#endif
