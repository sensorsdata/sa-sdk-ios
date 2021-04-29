//
// SAVisualizedManager.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/12/25.
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
#import <UIKit/UIKit.h>
#import "SAModuleProtocol.h"
#import "SAVisualPropertiesTracker.h"
#import "SAVisualizedEventCheck.h"

typedef NS_ENUM(NSInteger, SensorsAnalyticsVisualizedType) {
    SensorsAnalyticsVisualizedTypeUnknown,  // 未知或不允许
    SensorsAnalyticsVisualizedTypeHeatMap, // 点击图
    SensorsAnalyticsVisualizedTypeAutoTrack  //可视化全埋点
};

NS_ASSUME_NONNULL_BEGIN

@interface SAVisualizedManager : NSObject<SAModuleProtocol, SAOpenURLProtocol, SAVisualizedModuleProtocol>

@property (class,nonatomic, strong, readonly)SAVisualizedManager *sharedInstance;

@property (nonatomic, assign, getter=isEnable) BOOL enable;

@property (nonatomic, strong) SAConfigOptions *configOptions;

/// 自定义属性采集
@property (nonatomic, strong, readonly) SAVisualPropertiesTracker *visualPropertiesTracker;

/// 当前连接类型
@property (nonatomic, assign, readonly) SensorsAnalyticsVisualizedType visualizedType;

/// 可视化全埋点配置资源
@property (nonatomic, strong, readonly) SAVisualPropertiesConfigSources *configSources;

/// 埋点校验
@property (nonatomic, strong, readonly) SAVisualizedEventCheck *eventCheck;

/// 是否开启埋点校验
- (void)enableEventCheck:(BOOL)enable;
@end

NS_ASSUME_NONNULL_END
