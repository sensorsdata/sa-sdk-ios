//
// SALocationManager.h
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/5/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SALocationManager : NSObject <SAPropertyModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) SAConfigOptions *configOptions;
@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end

@interface SAConfigOptions (Location)

@property (nonatomic, assign) BOOL enableLocation NS_EXTENSION_UNAVAILABLE("Location not supported for iOS extensions.");

@end

NS_ASSUME_NONNULL_END
