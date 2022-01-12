//
// SAVisualPropertiesTracker.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law orviewNodeTree agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SAVisualPropertiesConfigSources.h"
#import "SAViewNodeTree.h"

NS_ASSUME_NONNULL_BEGIN


@interface SAVisualPropertiesTracker : NSObject

- (instancetype)initWithConfigSources:(SAVisualPropertiesConfigSources *)configSources;

@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;

@property (atomic, strong, readonly) SAViewNodeTree *viewNodeTree;

#pragma mark view changed
/// 视图添加或移除
- (void)didMoveToSuperviewWithView:(UIView *)view;

- (void)didMoveToWindowWithView:(UIView *)view;

// 添加子视图
- (void)didAddSubview:(UIView *)subview;

/// 成为 keyWindow
- (void)becomeKeyWindow:(UIWindow *)window;

/// 进入 RN 的自定义 viewController
- (void)enterRNViewController:(UIViewController *)viewController;

#pragma mark visualProperties

/// 采集元素自定义属性
/// @param view 触发事件的元素
/// @param completionHandler 采集完成回调
- (void)visualPropertiesWithView:(UIView *)view completionHandler:(void (^)(NSDictionary *_Nullable visualProperties))completionHandler;


/// 根据配置，采集属性
/// @param propertyConfigs 自定义属性配置
/// @param completionHandler 采集完成回调
- (void)queryVisualPropertiesWithConfigs:(NSArray <NSDictionary *>*)propertyConfigs completionHandler:(void (^)(NSDictionary *_Nullable properties))completionHandler;

#pragma mark debugInfo
/// 设置采集诊断日志
- (void)enableCollectDebugLog:(BOOL)enable;

@property (nonatomic, copy, readonly) NSArray <NSDictionary *>*logInfos;


@end


NS_ASSUME_NONNULL_END
