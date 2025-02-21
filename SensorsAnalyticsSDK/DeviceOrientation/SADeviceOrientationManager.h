//
// SADeviceOrientationManager.h
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/5/21.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (DeviceOrientation)

@property (nonatomic, assign) BOOL enableDeviceOrientation NS_EXTENSION_UNAVAILABLE("DeviceOrientation not supported for iOS extensions.");

@end

@interface SADeviceOrientationManager : NSObject <SAPropertyModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) SAConfigOptions *configOptions;
@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end

NS_ASSUME_NONNULL_END
