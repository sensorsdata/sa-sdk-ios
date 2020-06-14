//
// SAPresetProperty.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/5/12.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
@class SADeviceOrientationConfig;
#endif

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
@class SAGPSLocationConfig;
#endif

NS_ASSUME_NONNULL_BEGIN

extern NSString * const SAEventPresetPropertyDeviceID;

/// SDK 类型
extern NSString * const SAEventPresetPropertyLib;
/// SDK 方法
extern NSString * const SAEventPresetPropertyLibMethod;
/// SDK 版本
extern NSString * const SAEventPresetPropertyLibVersion;
/// SDK 调用栈
extern NSString * const SAEventPresetPropertyLibDetail;
/// 应用版本
extern NSString * const SAEventPresetPropertyAppVersion;

extern NSString * const SAEventPresetPropertyNetworkType;
extern NSString * const SAEventPresetPropertyWifi;
/// 是否首日
extern NSString * const SAEventPresetPropertyIsFirstDay;

#pragma mark -
@interface SAPresetProperty : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary *automaticProperties;
@property (nonatomic, copy, readonly) NSString *appVersion;
@property (nonatomic, copy, readonly) NSString *deviceID;

/**
 初始化方法
 
 @param queue 一个全局队列
 @param libVersion SDK 版本
 
 @return 初始化对象
 */
- (instancetype)initWithQueue:(dispatch_queue_t)queue libVersion:(NSString *)libVersion NS_DESIGNATED_INITIALIZER;

/// 禁用 init 初始化
- (instancetype)init NS_UNAVAILABLE;

/// 禁用 new 初始化
+ (instancetype)new NS_UNAVAILABLE;

/**
获取 lib 相关属性

@param method SDK 方法

@return lib 相关属性
*/
- (NSMutableDictionary *)libPropertiesWithMethod:(NSString *)method;

/// 是否为首日
- (BOOL)isFirstDay;

/// 当前的网络属性
- (NSDictionary *)currentNetworkProperties;

/// 当前的预置属性
- (NSDictionary *)currentPresetProperties;

/**
 track 类型特有的预置属性

 @param isLaunchedPassively 是否是被动启动
 @param orientationConfig 方向信息
 @param locationConfig 位置信息

 @return 当前的预置属性
*/
- (NSDictionary *)presetPropertiesOfTrackType:(BOOL)isLaunchedPassively
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
                            orientationConfig:(SADeviceOrientationConfig *)orientationConfig
#endif
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
                               locationConfig:(SAGPSLocationConfig *)locationConfig
#endif
;

@end

NS_ASSUME_NONNULL_END
