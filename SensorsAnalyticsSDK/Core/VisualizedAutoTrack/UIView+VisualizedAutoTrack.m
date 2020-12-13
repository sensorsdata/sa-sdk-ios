//
// UIView+VisualizedAutoTrack.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/6.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <objc/runtime.h>
#import "UIView+VisualizedAutoTrack.h"
#import "UIView+AutoTrack.h"
#import "UIViewController+AutoTrack.h"
#import "SAVisualizedUtils.h"
#import "SAAutoTrackUtils.h"
#import "SAConstants+Private.h"

@implementation UIView (VisualizedAutoTrack)

// 判断一个 view 是否显示
- (BOOL)sensorsdata_isDisplayedInScreen {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    /* 忽略部分 view
     _UIAlertControllerTextFieldViewCollectionCell，包含 UIAlertController 中输入框，忽略采集
     */
    if ([NSStringFromClass(self.class) isEqualToString:@"_UIAlertControllerTextFieldViewCollectionCell"]) {
        return NO;
    }

    /* 特殊场景兼容
     controller1.vew 上直接添加 controller2.view，在 controller2 添加 UITabBarController 或 UINavigationController 作为 childViewController；
     此时如果 UITabBarController 或 UINavigationController 使用 presentViewController 弹出页面，则 UITabBarController.view (即为 UILayoutContainerView) 可能未 hidden，为了可以通过 UILayoutContainerView 找到 UITabBarController 的子元素，则这里特殊处理。
       */
    if ([NSStringFromClass(self.class) isEqualToString:@"UILayoutContainerView"] && [self.nextResponder isKindOfClass:UIViewController.class]) {
        UIViewController *controller = (UIViewController *)[self nextResponder];
        if (controller.presentedViewController) {
            return YES;
        }
    }
#endif

    if (!(self.window && self.superview) || ![SAVisualizedUtils isVisibleForView:self]) {
        return NO;
    }
    // 计算 view 在 keyWindow 上的坐标
    CGRect rect = [self convertRect:self.frame toView:nil];
    // 若 size 为 CGrectZero
    // 部分 view 设置宽高为 0，但是子视图可见，取消 CGRectIsEmpty(rect) 判断
    if (CGRectIsNull(rect) || CGSizeEqualToSize(rect.size, CGSizeZero)) {
        return NO;
    }

    // RN 项目，view 覆盖层次比较多，被覆盖元素，可以直接屏蔽，防止被覆盖元素可圈选
    BOOL isRNView = [SAVisualizedUtils isKindOfRNView:self];
    if (isRNView && [SAVisualizedUtils isCoveredForView:self]) {
        return NO;
    }

    return YES;
}

/// 判断 ReactNative 元素是否可点击
- (BOOL)sensorsdata_clickableForRNView {
    // RN 可点击元素的区分
    Class managerClass = NSClassFromString(@"SAReactNativeManager");
    SEL sharedInstanceSEL = NSSelectorFromString(@"sharedInstance");
    if (managerClass && [managerClass respondsToSelector:sharedInstanceSEL]) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id manager = [managerClass performSelector:sharedInstanceSEL];
        SEL clickableSEL = NSSelectorFromString(@"clickableForView:");
        if ([manager respondsToSelector:clickableSEL]) {
            BOOL clickable = (BOOL)[manager performSelector:clickableSEL withObject:self];
            if (clickable) {
                return YES;
            }
        }
    #pragma clang diagnostic pop
    }
    return NO;
}

/// 解析 ReactNative 元素页面信息
- (NSDictionary *)sensorsdata_RNElementScreenProperties {
    SEL screenPropertiesSEL = NSSelectorFromString(@"sa_reactnative_screenProperties");
    // 获取 RN 元素所在页面信息
    if ([self respondsToSelector:screenPropertiesSEL]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSDictionary *screenProperties = (NSDictionary *)[self performSelector:screenPropertiesSEL];
        if (screenProperties) {
            return screenProperties;
        }
        #pragma clang diagnostic pop
    } else {
        // 获取 RN 页面信息
        return [SAVisualizedUtils currentRNScreenVisualizeProperties];
    }
    return nil;
}

// 判断一个 view 是否会触发全埋点事件
- (BOOL)sensorsdata_isAutoTrackAppClick {
    // 判断是否被覆盖
    if ([SAVisualizedUtils isCoveredForView:self]) {
        return NO;
    }

    // 标记弹框
    if ([SAAutoTrackUtils isAlertClickForView:self]) {
        return YES;
    }

    if ([self sensorsdata_clickableForRNView]) {
        return YES;
    }

    if ([self isKindOfClass:UIControl.class]) {
        // UISegmentedControl 高亮渲染内部嵌套的 UISegment
        if ([self isKindOfClass:UISegmentedControl.class]) {
            return NO;
        }

        // 部分控件，响应链中不采集 $AppClick 事件
        if ([self isKindOfClass:UITextField.class]) {
            return NO;
        }

        UIControl *control = (UIControl *)self;
        BOOL userInteractionEnabled = control.userInteractionEnabled;
        BOOL enabled = control.enabled;
        UIControlEvents appClickEvents = UIControlEventTouchUpInside | UIControlEventValueChanged;
        if (@available(iOS 9.0, *)) {
            appClickEvents = appClickEvents | UIControlEventPrimaryActionTriggered;
        }
        BOOL containEvents = appClickEvents & control.allControlEvents;
        if (containEvents && userInteractionEnabled && enabled) { // 可点击
            return YES;
        }
    } else if ([self isKindOfClass:UIImageView.class] || [self isKindOfClass:UILabel.class]) { // 可能添加手势
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
        // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
        if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
            return YES;
        }
#endif
        if (self.userInteractionEnabled && self.gestureRecognizers.count > 0) {
            __block BOOL enableGestureClick = NO;
            [self.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                // 目前 $AppClick 只采集 UITapGestureRecognizer 和 UILongPressGestureRecognizer
                if ([obj isKindOfClass:UITapGestureRecognizer.class] || [obj isKindOfClass:UILongPressGestureRecognizer.class]) {
                    *stop = YES;
                    enableGestureClick = YES;
                }
            }];
            return enableGestureClick;
        } else {
            return NO;
        }
    } else if ([self isKindOfClass:UITableViewCell.class]) {
        UITableView *tableView = (UITableView *)[self superview];
        do {
            if ([tableView isKindOfClass:UITableView.class]) {
                if (tableView.delegate && [tableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                    return YES;
                }
            }
        } while ((tableView = (UITableView *)[tableView superview]));

        return NO;
    } else if ([self isKindOfClass:UICollectionViewCell.class]) {
        UICollectionView *collectionView = (UICollectionView *)[self superview];
        if ([collectionView isKindOfClass:UICollectionView.class]) {
            if (collectionView.delegate && [collectionView.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
                return YES;
            }
        }
        return NO;
    }
    return NO;
}

#pragma mark SAVisualizedViewPathProperty
// 当前元素，前端是否渲染成可交互
- (BOOL)sensorsdata_enableAppClick {
    //是否在屏幕显示
    BOOL isDisplayedInScreen = self.sensorsdata_isDisplayedInScreen;
    // 是否触发 $AppClick 事件
    BOOL isAutoTrackAppClick = self.sensorsdata_isAutoTrackAppClick;
    BOOL enableAppClick = isDisplayedInScreen && isAutoTrackAppClick;
    return enableAppClick;
}

- (NSString *)sensorsdata_elementValidContent {
    return self.sensorsdata_elementContent;
}

/// 元素子视图
- (NSArray *)sensorsdata_subElements {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    /* 特殊场景兼容
     controller1.vew 上直接添加 controller2.view，
     在 controller2 添加 UITabBarController 或 UINavigationController 作为 childViewController 场景兼容
     */
    if ([NSStringFromClass(self.class) isEqualToString:@"UILayoutContainerView"]) {
        if ([[self nextResponder] isKindOfClass:UIViewController.class]) {
            UIViewController *controller = (UIViewController *)[self nextResponder];
            return controller.sensorsdata_subElements;
        }
    }
#endif
    NSMutableArray *newSubViews = [NSMutableArray array];
    for (UIView *view in self.subviews) {
        if (view.sensorsdata_isDisplayedInScreen) {
            [newSubViews addObject:view];
        }
    }
    return newSubViews;
}

- (NSString *)sensorsdata_elementPath {
    // 处理特殊控件
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)[self superview];
        if ([segmentedControl isKindOfClass:UISegmentedControl.class]) {
            return [SAAutoTrackUtils viewSimilarPathForView:segmentedControl atViewController:segmentedControl.sensorsdata_viewController shouldSimilarPath:YES];
        }
    }
#endif
    if (self.sensorsdata_enableAppClick) {
        return [SAAutoTrackUtils viewSimilarPathForView:self atViewController:self.sensorsdata_viewController shouldSimilarPath:YES];
    } else {
        return nil;
    }
}

- (BOOL)sensorsdata_isFromWeb {
    return NO;
}

- (CGRect)sensorsdata_frame {
    CGRect showRect = [self convertRect:self.bounds toView:nil];
    if (self.superview && self.sensorsdata_enableAppClick) {
        CGRect validFrame = self.superview.sensorsdata_validFrame;
        showRect = CGRectIntersection(showRect, validFrame);
    }
    return showRect;
}

- (CGRect)sensorsdata_validFrame {
    CGRect validFrame = [UIApplication sharedApplication].keyWindow.frame;
    if (self.superview) {
        CGRect superViewValidFrame = [self.superview sensorsdata_validFrame];
        validFrame = CGRectIntersection(validFrame, superViewValidFrame);
    }
 return validFrame;
}

- (NSString *)sensorsdata_screenName {
    // 解析 ReactNative 元素页面名称
    if ([self sensorsdata_clickableForRNView]) {
        NSDictionary *screenProperties = [self sensorsdata_RNElementScreenProperties];
        // 如果 ReactNative 页面信息为空，则使用 Native 的
        NSString *screenName = screenProperties[SA_EVENT_PROPERTY_SCREEN_NAME];
        if (screenName) {
            return screenName;
        }
    }

    // 解析 Native 元素页面信息
    if (self.sensorsdata_viewController) {
        NSDictionary *autoTrackScreenProperties = [SAAutoTrackUtils propertiesWithViewController:self.sensorsdata_viewController];
        return autoTrackScreenProperties[SA_EVENT_PROPERTY_SCREEN_NAME];
    }
    return nil;
}

- (NSString *)sensorsdata_title {
    // 处理 ReactNative 元素
    if ([self sensorsdata_clickableForRNView]) {
        NSDictionary *screenProperties = [self sensorsdata_RNElementScreenProperties];
        // 如果 ReactNative 的 screenName 不存在，则判断页面信息不存在，即使用 Native 逻辑
        if (screenProperties[SA_EVENT_PROPERTY_SCREEN_NAME]) {
            return screenProperties[SA_EVENT_PROPERTY_TITLE];
        }
    }

    // 处理 Native 元素
    if (self.sensorsdata_viewController) {
        NSDictionary *autoTrackScreenProperties = [SAAutoTrackUtils propertiesWithViewController:self.sensorsdata_viewController];
        return autoTrackScreenProperties[SA_EVENT_PROPERTY_TITLE];
    }
    return nil;
}
@end


@implementation UIScrollView (VisualizedAutoTrack)

- (CGRect)sensorsdata_validFrame {
    CGRect showRect = [self convertRect:self.bounds toView:nil];
    if (self.superview) {
        CGRect superViewValidFrame = [self.superview sensorsdata_validFrame];
        showRect = CGRectIntersection(showRect, superViewValidFrame);
    }
    return showRect;
}

@end

@implementation UISwitch (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UIStepper (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UISlider (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UIPageControl (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation WKWebView (VisualizedAutoTrack)

- (NSArray *)sensorsdata_subElements {
    NSArray *subElements = [SAVisualizedUtils analysisWebElementWithWebView:self];
    if (subElements.count > 0) {
        return subElements;
    }
    return [super sensorsdata_subElements];
}

@end


@implementation UIWindow (VisualizedAutoTrack)

- (NSArray *)sensorsdata_subElements {
    if (!self.rootViewController) {
        return super.sensorsdata_subElements;
    }

    NSMutableArray *subElements = [NSMutableArray array];
    [subElements addObject:self.rootViewController];

    // 存在自定义弹框或浮层，位于 keyWindow
    NSArray <UIView *> *subviews = self.subviews;
    for (UIView *view in subviews) {
        if (view != self.rootViewController.view && view.sensorsdata_isDisplayedInScreen) {
            /*
             keyWindow 设置 rootViewController 后，视图层级为 UIWindow -> UITransitionView -> UIDropShadowView -> rootViewController.view
             */
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
            if ([NSStringFromClass(view.class) isEqualToString:@"UITransitionView"]) {
                continue;
            }
#endif
            [subElements addObject:view];

            CGRect rect = [view convertRect:view.bounds toView:nil];
            // 是否全屏
            BOOL isFullScreenShow = CGPointEqualToPoint(rect.origin, CGPointMake(0, 0)) && CGSizeEqualToSize(rect.size, self.bounds.size);
            // keyWindow 上存在全屏显示可交互的 view，此时 rootViewController 内元素不可交互
            if (isFullScreenShow && view.userInteractionEnabled) {
                [subElements removeObject:self.rootViewController];
            }
        }
    }
    return subElements;
}

@end

@implementation UITableView (VisualizedAutoTrack)

- (NSArray *)sensorsdata_subElements {
    NSArray *subviews = self.subviews;
    NSMutableArray *newSubviews = [NSMutableArray array];
    NSArray *visibleCells = self.visibleCells;
    for (UIView *view in subviews) {
        if ([view isKindOfClass:UITableViewCell.class]) {
            if ([visibleCells containsObject:view] && view.sensorsdata_isDisplayedInScreen) {
                [newSubviews addObject:view];
            }
        } else if (view.sensorsdata_isDisplayedInScreen) {
            [newSubviews addObject:view];
        }
    }
    return newSubviews;
}

@end

@implementation UICollectionView (VisualizedAutoTrack)

- (NSArray *)sensorsdata_subElements {
    NSArray *subviews = self.subviews;
    NSMutableArray *newSubviews = [NSMutableArray array];
    NSArray *visibleCells = self.visibleCells;
    for (UIView *view in subviews) {
        if ([view isKindOfClass:UICollectionViewCell.class]) {
            if ([visibleCells containsObject:view] && view.sensorsdata_isDisplayedInScreen) {
                [newSubviews addObject:view];
            }
        } else if (view.sensorsdata_isDisplayedInScreen) {
            [newSubviews addObject:view];
        }
    }

    // 根据位置排序
    NSArray *rankResult = [newSubviews sortedArrayUsingComparator:^NSComparisonResult (UIView *obj1, UIView *obj2) {
        if (obj2.frame.origin.y > obj1.frame.origin.y || obj2.frame.origin.x > obj1.frame.origin.x) {
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];

    return rankResult;
}

@end

@implementation UITableViewCell (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementPosition {
    if (self.sensorsdata_IndexPath) {
        return [[NSString alloc] initWithFormat:@"%ld:%ld", (long)self.sensorsdata_IndexPath.section, (long)self.sensorsdata_IndexPath.row];
    }
    return nil;
}

@end


@implementation UICollectionViewCell (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementPosition {
    if ([SAAutoTrackUtils isAlertClickForView:self]) {
        return nil;
    }

    if (self.sensorsdata_IndexPath) {
        return [[NSString alloc] initWithFormat:@"%ld:%ld", (long)self.sensorsdata_IndexPath.section, (long)self.sensorsdata_IndexPath.item];
    }
    return nil;
}

@end

@implementation SAJSTouchEventView (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementPath {
    return self.elementSelector;
}

- (NSString *)sensorsdata_elementValidContent {
    return self.elementContent;
}

- (CGRect)sensorsdata_frame {
    return self.frame;
}

- (BOOL)sensorsdata_enableAppClick {
    return YES;
}

- (NSArray *)sensorsdata_subElements {
    if (self.jsSubviews.count > 0) {
        return self.jsSubviews;
    }
    return [super sensorsdata_subElements];
}

- (BOOL)sensorsdata_isFromWeb {
    return YES;
}

@end

@implementation UIViewController (VisualizedAutoTrack)

- (NSArray *)sensorsdata_subElements {
    __block NSMutableArray *subElements = [NSMutableArray array];
    NSArray <UIViewController *> *childViewControllers = self.childViewControllers;
    UIViewController *presentedViewController = self.presentedViewController;

    if (presentedViewController) {
        [subElements addObject:presentedViewController];
        return subElements;
    }

    if ([self isKindOfClass:UINavigationController.class]) {
        UINavigationController *nav = (UINavigationController *)self;
        [subElements addObject:nav.topViewController];
        if (self.isViewLoaded && nav.navigationBar.sensorsdata_isDisplayedInScreen) {
            [subElements addObject:nav.navigationBar];
        }
        return subElements;
    }

    if ([self isKindOfClass:UITabBarController.class]) {
        UITabBarController *tabBarVC = (UITabBarController *)self;
        [subElements addObject:tabBarVC.selectedViewController];
        // UITabBar 元素
        if (self.isViewLoaded && tabBarVC.tabBar.sensorsdata_isDisplayedInScreen) {
            [subElements addObject:tabBarVC.tabBar];
        }
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
                    if (objSuperview.sensorsdata_isDisplayedInScreen && !isContainFullScreen) {
                        [subElements replaceObjectAtIndex:index withObject:obj];
                    } else {
                        [subElements removeObject:objSuperview];
                    }
                }
                CGRect rect = [obj.view convertRect:obj.view.bounds toView:nil];
               // 是否全屏
                BOOL isFullScreenShow = CGPointEqualToPoint(rect.origin, CGPointMake(0, 0)) && CGSizeEqualToSize(rect.size, keyWindow.bounds.size);
               // 正在全屏显示
                if (isFullScreenShow && obj.view.sensorsdata_isDisplayedInScreen) {
                    isContainFullScreen = YES;
                }
            }
        }];
        return subElements;
    }

    if ([self isKindOfClass:UIPageViewController.class]) {
        UIPageViewController *pageViewController = (UIPageViewController *)self;
        [subElements addObject:pageViewController.viewControllers];
    }

    UIView *currentView = self.view;
    if (currentView && self.isViewLoaded && currentView.sensorsdata_isDisplayedInScreen) {
        [subElements addObject:currentView];
    }
    return subElements;
}

@end
