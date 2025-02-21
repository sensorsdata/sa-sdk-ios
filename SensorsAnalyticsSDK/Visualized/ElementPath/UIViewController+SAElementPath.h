//
// UIViewController+SAElementPath.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/3/15.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SAVisualizedViewPathProperty.h"

NS_ASSUME_NONNULL_BEGIN


@interface UIViewController (SAElementPath)<SAVisualizedViewPathProperty>

- (void)sensorsdata_visualize_viewDidAppear:(BOOL)animated;

@end

@interface UITabBarController (SAElementPath)<SAVisualizedViewPathProperty>

@end

@interface UINavigationController (SAElementPath)<SAVisualizedViewPathProperty>

@end

@interface UIPageViewController (SAElementPath)<SAVisualizedViewPathProperty>

@end

NS_ASSUME_NONNULL_END
