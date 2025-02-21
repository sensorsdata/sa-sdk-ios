//
// SAEventTrackerPluginProtocol.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/11/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SAEventTrackerPluginProtocol <NSObject>

//install plugin
- (void)install;

//uninstall plugin
- (void)uninstall;

@optional
//track event with properties
- (void)trackWithProperties:(NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
