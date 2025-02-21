//
// UIView+SAInternalProperties.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/30.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+SAInternalProperties.h"
#import "SAUIProperties.h"

@implementation UIView (SAInternalProperties)

- (UIViewController<SAUIViewControllerInternalProperties> *)sensorsdata_viewController {
    UIViewController *viewController = [SAUIProperties findNextViewControllerByResponder:self];

    // 获取当前 controller 作为 screen_name
    if (!viewController || [viewController isKindOfClass:UIAlertController.class]) {
        viewController = [SAUIProperties currentViewController];
    }
    return (UIViewController<SAUIViewControllerInternalProperties> *)viewController;
}

- (UIScrollView *)sensorsdata_nearbyScrollView {
    return [self sensorsdata_nearbyScrollViewByView:self];
}

- (UIScrollView *)sensorsdata_nearbyScrollViewByView:(UIView *)view {
    UIView *superView = view.superview;
    if ([superView isKindOfClass:[UIScrollView class]] || !superView) {
        return (UIScrollView *)superView;
    }
    return [self sensorsdata_nearbyScrollViewByView:superView];
}

@end
