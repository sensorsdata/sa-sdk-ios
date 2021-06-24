//
// SAViewNodeTree.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/14.
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
#import "SAViewNode.h"
#import "SAVisualPropertiesConfig.h"

NS_ASSUME_NONNULL_BEGIN

/// 所有 view 节点树
@interface SAViewNodeTree : NSObject

/// 指定初始化方法，设置队列
/// @param queue 操作队列
/// @return 实例对象
- (instancetype)initWithQueue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;

/// 禁用默认初始化
- (instancetype)init NS_UNAVAILABLE;
/// 禁用默认初始化
- (instancetype)new NS_UNAVAILABLE;

/// 视图添加或移除
- (void)didMoveToSuperviewWithView:(UIView *)view;

- (void)didMoveToWindowWithView:(UIView *)view;

- (void)didAddSubview:(UIView *)subview;

- (void)becomeKeyWindow:(UIWindow *)window;

- (void)refreshRNViewScreenNameWithViewController:(UIViewController *)viewController;

/// 根据节点配置信息，获取 view
- (UIView *)viewWithPropertyConfig:(SAVisualPropertiesPropertyConfig *)config;

@end

NS_ASSUME_NONNULL_END
