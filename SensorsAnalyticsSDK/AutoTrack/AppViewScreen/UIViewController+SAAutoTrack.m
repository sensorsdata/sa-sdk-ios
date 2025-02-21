//
// UIViewController+SAAutoTrack.m
// SensorsAnalyticsSDK
//
// Created by 王灼洲 on 2017/10/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "UIViewController+SAAutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SACommonUtility.h"
#import "SALog.h"
#import "UIView+SAAutoTrack.h"
#import "SAAutoTrackManager.h"
#import "SAWeakPropertyContainer.h"
#import <objc/runtime.h>

static void *const kSAPreviousViewController = (void *)&kSAPreviousViewController;

@implementation UIViewController (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    return ![[SAAutoTrackManager defaultManager].appClickTracker shouldTrackViewController:self];
}

- (void)sa_autotrack_viewDidAppear:(BOOL)animated {
    // 防止 tabbar 切换，可能漏采 $AppViewScreen 全埋点
    if ([self isKindOfClass:UINavigationController.class]) {
        UINavigationController *nav = (UINavigationController *)self;
        nav.sensorsdata_previousViewController = nil;
    }

    SAAppViewScreenTracker *appViewScreenTracker = SAAutoTrackManager.defaultManager.appViewScreenTracker;

    // parentViewController 判断，防止开启子页面采集时候的侧滑多采集父页面 $AppViewScreen 事件
    if (self.navigationController && self.parentViewController == self.navigationController) {
        // 全埋点中，忽略由于侧滑部分返回原页面，重复触发 $AppViewScreen 事件
        if (self.navigationController.sensorsdata_previousViewController == self) {
            return [self sa_autotrack_viewDidAppear:animated];
        }
    }

    
    if (SAAutoTrackManager.defaultManager.configOptions.enableAutoTrackChildViewScreen ||
        !self.parentViewController ||
        [self.parentViewController isKindOfClass:[UITabBarController class]] ||
        [self.parentViewController isKindOfClass:[UINavigationController class]] ||
        [self.parentViewController isKindOfClass:[UIPageViewController class]] ||
        [self.parentViewController isKindOfClass:[UISplitViewController class]]) {
        [appViewScreenTracker autoTrackEventWithViewController:self];
    }

    // 标记 previousViewController
    if (self.navigationController && self.parentViewController == self.navigationController) {
        self.navigationController.sensorsdata_previousViewController = self;
    }

    [self sa_autotrack_viewDidAppear:animated];
}

@end

@implementation UINavigationController (AutoTrack)

- (void)setSensorsdata_previousViewController:(UIViewController *)sensorsdata_previousViewController {
    SAWeakPropertyContainer *container = [SAWeakPropertyContainer containerWithWeakProperty:sensorsdata_previousViewController];
    objc_setAssociatedObject(self, kSAPreviousViewController, container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)sensorsdata_previousViewController {
    SAWeakPropertyContainer *container = objc_getAssociatedObject(self, kSAPreviousViewController);
    return container.weakProperty;
}

@end
