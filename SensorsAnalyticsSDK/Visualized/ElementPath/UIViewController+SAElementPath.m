//
// UIViewController+SAElementPath.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/3/15.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIViewController+SAElementPath.h"
#import "SAVisualizedUtils.h"
#import "SAAutoTrackUtils.h"
#import "UIView+SAElementPath.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAVisualizedObjectSerializerManager.h"
#import "SAVisualizedManager.h"
#import "SAAutoTrackManager.h"

@implementation UIViewController (SAElementPath)

- (NSString *)sensorsdata_heatMapPath {
    return [SAVisualizedUtils itemHeatMapPathForResponder:self];
}

- (NSArray *)sensorsdata_subElements {
    __block NSMutableArray *subElements = [NSMutableArray array];
    NSArray <UIViewController *> *childViewControllers = self.childViewControllers;
    UIViewController *presentedViewController = self.presentedViewController;

    if (presentedViewController) {
        [subElements addObject:presentedViewController];
        return subElements;
    }

    if (childViewControllers.count > 0 && ![self isKindOfClass:UIAlertController.class]) {
        // UIAlertController 如果添加 TextField 也会嵌套 childViewController，直接返回 .view 即可

        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        subElements = [NSMutableArray arrayWithArray:self.view.subviews];
        // 是否包含全屏视图
        __block BOOL isContainFullScreen = NO;
        //逆序遍历
        [childViewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if (obj.isViewLoaded) {
                UIView *objSuperview = obj.view;
                if ([subElements containsObject:objSuperview]) {
                    NSInteger index = [subElements indexOfObject:objSuperview];
                    if (objSuperview.sensorsdata_isVisible && !isContainFullScreen) {
                        [subElements replaceObjectAtIndex:index withObject:obj];
                    } else {
                        [subElements removeObject:objSuperview];
                    }
                }
                CGRect rect = [obj.view convertRect:obj.view.bounds toView:nil];
               // 是否全屏
                BOOL isFullScreenShow = CGPointEqualToPoint(rect.origin, CGPointZero) && CGSizeEqualToSize(rect.size, keyWindow.bounds.size);
               // 正在全屏显示
                if (isFullScreenShow && obj.view.sensorsdata_isVisible) {
                    isContainFullScreen = YES;
                }
            }
        }];
        return subElements;
    }

    UIView *currentView = self.view;
    if (currentView && self.isViewLoaded && currentView.sensorsdata_isVisible) {
        [subElements addObject:currentView];
    }
    return subElements;
}

- (void)sensorsdata_visualize_viewDidAppear:(BOOL)animated {
    [self sensorsdata_visualize_viewDidAppear:animated];

    if (SAAutoTrackManager.sharedInstance.configOptions.enableAutoTrackChildViewScreen ||
        !self.parentViewController ||
        [self.parentViewController isKindOfClass:[UITabBarController class]] ||
        [self.parentViewController isKindOfClass:[UINavigationController class]] ||
        [self.parentViewController isKindOfClass:[UIPageViewController class]] ||
        [self.parentViewController isKindOfClass:[UISplitViewController class]]) {
        [self sensorsdata_readyEnterViewController];
    }

    // 跳转进入 RN 自定义页面，需更新节点的页面名称
    if ([SAVisualizedUtils isRNCustomViewController:self]) {
        [SAVisualizedManager.sharedInstance.visualPropertiesTracker enterRNViewController:self];
    }
}

- (void)sensorsdata_readyEnterViewController {
    if (![[SAAutoTrackManager sharedInstance].appViewScreenTracker shouldTrackViewController:self]) {
        return;
    }
    // 保存最后一次页面浏览所在的 controller，用于可视化全埋点定义页面浏览
    [[SAVisualizedObjectSerializerManager sharedInstance] enterViewController:self];
}

@end

@implementation UIAlertController (SAElementPath)

- (NSString *)sensorsdata_itemPath {
    NSString *className = NSStringFromClass(self.class);
    NSInteger index = [SAAutoTrackUtils itemIndexForResponder:self];
    if (index < -1) {
        return className;
    }

    if (index < 0) {
        index = 0;
    }
    return [NSString stringWithFormat:@"%@[%ld]", className, (long)index];
}

- (NSString *)sensorsdata_similarPath {
    return self.sensorsdata_itemPath;
}

@end

@implementation UITabBarController (SAElementPath)
- (NSArray *)sensorsdata_subElements {
    NSMutableArray *subElements = [NSMutableArray array];
    if (self.presentedViewController) {
        [subElements addObject:self.presentedViewController];
        return subElements;
    }

    /* 兼容场景
     可能存在元素，直接添加在 UITabBarController.view 上（即 UILayoutContainerView）
     UITabBarController 页面层级大致如下
     - UITabBarController
        - UILayoutContainerView
            - UITransitionView
            - UITabBar
     */
    NSArray<UIView *> *subViews = self.view.subviews;
    for (UIView *view in subViews) {
        if ([view isKindOfClass:UITabBar.class]) {
            // UITabBar 元素
            if (self.isViewLoaded && self.tabBar.sensorsdata_isVisible) {
                [subElements addObject:self.tabBar];
            }
        } else if ([NSStringFromClass(view.class) isEqualToString:@"UITransitionView"]) {
            if (self.selectedViewController) {
                [subElements addObject:self.selectedViewController];
            }
        } else if (view.sensorsdata_isVisible) {
            [subElements addObject:view];
        }
    }

    return subElements;
}
@end


@implementation UINavigationController (SAElementPath)
- (NSArray *)sensorsdata_subElements {
    NSMutableArray *subElements = [NSMutableArray array];
    if (self.presentedViewController) {
        [subElements addObject:self.presentedViewController];
        return subElements;
    }
    /* 兼容场景
     可能存在元素，直接添加在 UINavigationController.view 上（即 UILayoutContainerView）
     UINavigationController 页面层级大致如下
     - UINavigationController
        - UILayoutContainerView
            - UINavigationTransitionView
            - UINavigationBar
     */
    NSArray<UIView *> *subViews = self.view.subviews;
    for (UIView *view in subViews) {
        if ([view isKindOfClass:UINavigationBar.class]) {
            // UINavigationBar 元素
            if (self.isViewLoaded && self.navigationBar.sensorsdata_isVisible) {
                [subElements addObject:self.navigationBar];
            }
        } else if ([NSStringFromClass(view.class) isEqualToString:@"UINavigationTransitionView"]) {
            if (self.topViewController) {
                [subElements addObject:self.topViewController];
            }
        } else if (view.sensorsdata_isVisible) {
            [subElements addObject:view];
        }
    }
    return subElements;
}
@end

@implementation UIPageViewController (SAElementPath)

- (NSArray *)sensorsdata_subElements {
    NSMutableArray *subElements = [NSMutableArray array];
    if (self.presentedViewController) {
        [subElements addObject:self.presentedViewController];
        return subElements;
    }

    /* 兼容场景
     可能存在元素，直接添加在 UIPageViewController.view 上（即 _UIPageViewControllerContentView）
     UIPageViewController 页面层级大致如下
     - UIPageViewController
        - _UIPageViewControllerContentView
            - _UIQueuingScrollView
            - Others
     */
    for (UIView *view in self.view.subviews) {
        if ([NSStringFromClass(view.class) isEqualToString:@"_UIQueuingScrollView"]) {
            if (self.viewControllers.count > 0) {
                [subElements addObjectsFromArray:self.viewControllers];
            }
        } else if (view.sensorsdata_isVisible) {
            [subElements addObject:view];
        }
    }
    return subElements;
}

@end

