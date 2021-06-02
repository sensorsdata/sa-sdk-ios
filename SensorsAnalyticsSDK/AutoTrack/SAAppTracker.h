//
// SAAppTracker.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/5/20.
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

#import <UIKit/UIKit.h>
#import "SAConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAppTracker : NSObject

/// 是否忽略事件
@property (nonatomic, assign, getter=isIgnored) BOOL ignored;
/// 是否被动启动
@property (nonatomic, assign, getter=isPassively) BOOL passively;
/// 用户设置的不被 AutoTrack 的 Controllers
@property (nonatomic, strong) NSMutableSet<NSString *> *ignoredViewControllers;

/// 获取 tracker 对应的事件 ID
- (NSString *)eventId;

/// 触发全埋点事件
/// @param properties 事件属性
- (void)trackAutoTrackEventWithProperties:(nullable NSDictionary *)properties;

/// 触发手动采集预置事件
/// @param properties 事件属性
- (void)trackPresetEventWithProperties:(nullable NSDictionary *)properties;

/// 根据 UIViewController 判断，是否采集事件
/// @param viewController 事件采集时的控制器
- (BOOL)shouldTrackViewController:(UIViewController *)viewController;

/// 在 AutoTrack 时，用户可以设置哪些 controllers 不被 AutoTrack
/// @param controllers controller ‘字符串’数组
- (void)ignoreAutoTrackViewControllers:(NSArray<NSString *> *)controllers;

/// 判断某个 ViewController 是否被忽略
/// @param viewController UIViewController
- (BOOL)isViewControllerIgnored:(UIViewController *)viewController;

/// 判断某个 ViewController 是否被忽略
/// @param viewControllerClassName UIViewController 类名
- (BOOL)isViewControllerStringIgnored:(NSString *)viewControllerClassName;

/// ViewController 的黑名单
- (NSDictionary *)autoTrackViewControllerBlackList;

/// 判断某个 ViewController 是否处于黑名单
/// @param viewController UIViewController
/// @param blackList 黑名单
- (BOOL)isViewController:(UIViewController *)viewController inBlackList:(NSDictionary *)blackList;

@end

NS_ASSUME_NONNULL_END
