//
// SAAppViewScreenTracker.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/4/27.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SAAppTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAppViewScreenTracker : SAAppTracker

/// 触发全埋点页面浏览事件
/// @param viewController 触发页面浏览的 UIViewController
- (void)autoTrackEventWithViewController:(UIViewController *)viewController;

/// 通过代码触发页面浏览事件
/// @param viewController 当前的 UIViewController
/// @param properties 用户扩展属性
- (void)trackEventWithViewController:(UIViewController *)viewController properties:(NSDictionary<NSString *, id> * _Nullable)properties;

/// 通过代码触发页面浏览事件
/// @param url 当前页面 url
/// @param properties 用户扩展属性
- (void)trackEventWithURL:(NSString *)url properties:(NSDictionary<NSString *, id> * _Nullable)properties;

/// 触发被动启动时的页面浏览事件
- (void)trackEventOfLaunchedPassively;

@end

NS_ASSUME_NONNULL_END
