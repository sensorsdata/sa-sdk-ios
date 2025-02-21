//
// SAEventTrackerPluginManager.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/11/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAEventTrackerPlugin.h"
#import "SAEventTrackerPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAEventTrackerPluginManager : NSObject

+ (instancetype)defaultManager;

//register plugin and install
- (void)registerPlugin:(SAEventTrackerPlugin<SAEventTrackerPluginProtocol> *)plugin;
- (void)unregisterPlugin:(Class)pluginClass;
- (void)unregisterAllPlugins;

- (void)enableAllPlugins;
- (void)disableAllPlugins;

- (SAEventTrackerPlugin<SAEventTrackerPluginProtocol> *)pluginWithType:(NSString *)pluginType;

@end

NS_ASSUME_NONNULL_END
