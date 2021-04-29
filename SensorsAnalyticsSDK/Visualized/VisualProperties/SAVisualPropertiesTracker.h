//
// SAVisualPropertiesTracker.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/6.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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
#import "SAVisualPropertiesConfigSources.h"

NS_ASSUME_NONNULL_BEGIN


@interface SAVisualPropertiesTracker : NSObject

- (instancetype)initWithConfigSources:(SAVisualPropertiesConfigSources *)configSources;

/// 视图添加或移除
- (void)didMoveToSuperviewWithView:(UIView *)view;

- (void)didMoveToWindowWithView:(UIView *)view;

// 添加子视图
- (void)didAddSubview:(UIView *)subview;

#pragma mark visualProperties

/// 采集元素自定义属性
/// @param view 触发事件的元素
/// @param completionHandler 采集完成回调
- (void)visualPropertiesWithView:(UIView *)view completionHandler:(void (^)(NSDictionary *_Nullable visualProperties))completionHandler;

#pragma mark debugInfo
/// 设置采集诊断日志
- (void)enableCollectDebugLog:(BOOL)enable;

@property (nonatomic, copy, readonly) NSArray <NSDictionary *>*logInfos;

@end


NS_ASSUME_NONNULL_END
