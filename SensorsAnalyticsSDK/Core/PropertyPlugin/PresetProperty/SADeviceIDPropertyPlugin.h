//
// SADeviceIDPropertyPlugin.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/10/25.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSADeviceIDPropertyPluginAnonymizationID;
extern NSString * const kSADeviceIDPropertyPluginDeviceID;

@interface SADeviceIDPropertyPlugin : SAPropertyPlugin

@property (nonatomic, assign) BOOL disableDeviceId;

@end

NS_ASSUME_NONNULL_END
