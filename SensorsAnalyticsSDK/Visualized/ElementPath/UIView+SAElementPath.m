//
// UIView+SAElementPath.m
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
#import "UIView+SAElementPath.h"
#import "UIView+AutoTrack.h"
#import "UIViewController+AutoTrack.h"
#import "UIViewController+SAElementPath.h"
#import "SAVisualizedUtils.h"
#import "SAAutoTrackUtils.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAViewElementInfoFactory.h"

typedef BOOL (*SAClickableImplementation)(id, SEL, UIView *);

#pragma mark - UIView
@implementation UIView (SAElementPath)

// 判断一个 view 是否显示
- (BOOL)sensorsdata_isVisible {
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
    CGRect rect = [self convertRect:self.bounds toView:nil];
    // 若 size 为 CGrectZero
    // 部分 view 设置宽高为 0，但是子视图可见，取消 CGRectIsEmpty(rect) 判断
    if (CGRectIsNull(rect) || CGSizeEqualToSize(rect.size, CGSizeZero)) {
        return NO;
    }

    // RN 项目，view 覆盖层次比较多，被覆盖元素，可以直接屏蔽，防止被覆盖元素可圈选
    BOOL isRNView = [SAAutoTrackUtils isKindOfRNView:self];
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
#pragma clang diagnostic pop
        SEL clickableSEL = NSSelectorFromString(@"clickableForView:");
        IMP clickableImp = [manager methodForSelector:clickableSEL];
        if (clickableImp) {
            return ((SAClickableImplementation)clickableImp)(manager, clickableSEL, self);
        }
    }
    return NO;
}

/// 解析 ReactNative 元素页面信息
- (NSDictionary *)sensorsdata_RNElementScreenProperties {
    SEL screenPropertiesSEL = NSSelectorFromString(@"sa_reactnative_screenProperties");
    // 获取 RN 元素所在页面信息
    if ([self respondsToSelector:screenPropertiesSEL]) {
        /* 处理说明
         在 RN 项目中，如果当前页面为 RN 页面，页面名称为 "Home"，如果弹出某些页面，其实是 Native 的自定义 UIViewController（比如 RCTModalHostViewController），会触发 Native 的 $AppViewScreen 事件。
         弹出页面的上的元素，依然为 RN 元素。按照目前 RN 插件的逻辑，这些元素触发 $AppClick 全埋点中的 $screen_name 为 "Home"。
         为了确保可视化全埋点上传页面信息中可点击元素获取页面名称（screenName）和 $AppClick 全埋点中的 $screen_name 保持一致，事件正确匹配。所以针对 RN 针对可点击元素，使用扩展属性绑定元素所在页面信息。
         详见 RNSensorsAnalyticsModule 实现：https://github.com/sensorsdata/react-native-sensors-analytics/tree/master/ios
         */
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSDictionary *screenProperties = (NSDictionary *)[self performSelector:screenPropertiesSEL];
        if (screenProperties) {
            return screenProperties;
        }
        #pragma clang diagnostic pop
    }
        // 获取 RN 页面信息
    return [SAVisualizedUtils currentRNScreenVisualizeProperties];
}

// 判断一个 view 是否会触发全埋点事件
- (BOOL)sensorsdata_isAutoTrackAppClick {
    // 判断是否被覆盖
    if ([SAVisualizedUtils isCoveredForView:self]) {
        return NO;
    }
    
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)[self superview];
        if (![segmentedControl isKindOfClass:UISegmentedControl.class]) {
            return NO;
        }
        // 可能是 RN 框架 中 RCTSegmentedControl 内嵌 UISegment，再执行一次 RN 的可点击判断
        BOOL clickable = [SAVisualizedUtils isAutoTrackAppClickWithControl:segmentedControl];
        if (clickable){
            return YES;
        }
    }
#endif

    if ([self sensorsdata_clickableForRNView]) {
        return YES;
    }

    // Native 全埋点被忽略元素，不可圈选，RN 全埋点事件由插件触发，不经过此判断
    if (self.sensorsdata_isIgnored) {
        return NO;
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
        if ([SAVisualizedUtils isAutoTrackAppClickWithControl:control]) {
            return YES;
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
    } else if ([self isKindOfClass:UICollectionViewCell.class]) {
        UICollectionView *collectionView = (UICollectionView *)[self superview];
        if ([collectionView isKindOfClass:UICollectionView.class]) {
            if (collectionView.delegate && [collectionView.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
                return YES;
            }
        }
    }
    
    SAViewElementInfo *elementInfo = [SAViewElementInfoFactory elementInfoWithView:self];
    return elementInfo.isVisualView;
}

#pragma mark SAAutoTrackViewPathProperty
- (NSString *)sensorsdata_itemPath {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    /* 忽略路径
     UITableViewWrapperView 为 iOS11 以下 UITableView 与 cell 之间的 view
     _UITextFieldCanvasView 和 _UISearchBarFieldEditor 都是 UISearchBar 内部私有 view
     在输入状态下  ...UISearchBarTextField/_UISearchBarFieldEditor/_UITextFieldCanvasView/...
     非输入状态下 .../UISearchBarTextField/_UITextFieldCanvasView
     并且 _UITextFieldCanvasView 是个私有 view,无法获取元素内容(目前通过 nextResponder 获取 textField 采集内容)。方便路径统一，所以忽略 _UISearchBarFieldEditor 路径
     */
    if ([SAVisualizedUtils isIgnoredItemPathWithView:self]) {
        return nil;
    }
#endif

    NSString *className = NSStringFromClass(self.class);
    NSInteger index = [SAAutoTrackUtils itemIndexForResponder:self];
    if (index < -1) { // -2
        return className;
    }

    if (index < 0) { // -1
        index = 0;
    }
    return [NSString stringWithFormat:@"%@[%ld]", className, (long)index];
}

- (NSString *)sensorsdata_heatMapPath {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
        /* 忽略路径
         UITableViewWrapperView 为 iOS11 以下 UITableView 与 cell 之间的 view
         */
        if ([NSStringFromClass(self.class) isEqualToString:@"UITableViewWrapperView"] || [NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
            return nil;
        }
#endif

    NSString *identifier = [SAVisualizedUtils viewIdentifierForView:self];
    if (identifier) {
        return identifier;
    }
    return [SAVisualizedUtils itemHeatMapPathForResponder:self];
}

- (NSString *)sensorsdata_similarPath {
    // 是否支持限定元素位置功能
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    BOOL enableSupportSimilarPath = [NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"];
#else
    BOOL enableSupportSimilarPath = NO;
#endif

    if (self.sensorsdata_elementPosition && enableSupportSimilarPath) {
        NSString *similarPath = [NSString stringWithFormat:@"%@[-]",NSStringFromClass(self.class)];
        return similarPath;
    } else {
        return self.sensorsdata_itemPath;
    }
}

#pragma mark SAVisualizedViewPathProperty
// 当前元素，前端是否渲染成可交互
- (BOOL)sensorsdata_enableAppClick {
    // 是否在屏幕显示
    // 是否触发 $AppClick 事件
    return self.sensorsdata_isVisible && self.sensorsdata_isAutoTrackAppClick;
}

- (NSString *)sensorsdata_elementValidContent {
    /*
     针对 RN 元素，上传页面信息中的元素内容，和 RN 插件触发全埋点一致，不遍历子视图元素内容
     获取 RN 元素自定义属性，会尝试遍历子视图
     */
    if ([SAAutoTrackUtils isKindOfRNView:self]) {
        return [self.accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    return self.sensorsdata_elementContent;
}

/// 元素子视图
- (NSArray *)sensorsdata_subElements {
    //  部分元素，忽略子视图
    if ([SAVisualizedUtils isIgnoreSubviewsWithView:self]) {
        return nil;
    }
    
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
        if (view.sensorsdata_isVisible) {
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
            return [SAVisualizedUtils viewSimilarPathForView:segmentedControl atViewController:segmentedControl.sensorsdata_viewController shouldSimilarPath:YES];
        }
    }
#endif
    // 支持自定义属性，可见元素均上传 elementPath
    return [SAVisualizedUtils viewSimilarPathForView:self atViewController:self.sensorsdata_viewController shouldSimilarPath:YES];
}

- (NSString *)sensorsdata_elementSelector {
    // 处理特殊控件
    #ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)[self superview];
        if ([segmentedControl isKindOfClass:UISegmentedControl.class]) {
            /* 原始路径，都是类似以下结构：
             UINavigationController/AutoTrackViewController/UIView/UISegmentedControl[(jjf_varB='fac459bd36d8326d9140192c7900decaf3744f5e')]/UISegment[0]
             UISegment[0] 无法标识当前单元格当前显示的序号 index
             */
            NSString *elementSelector = [SAVisualizedUtils viewPathForView:segmentedControl atViewController:segmentedControl.sensorsdata_viewController];
            // 解析 UISegment 的显示序号 index
            NSString *postion = [self sensorsdata_elementPosition];
            // 原始路径分割后的集合
            NSMutableArray <NSString *> *viewPaths = [[elementSelector componentsSeparatedByString:@"/"] mutableCopy];
            // 删除最后一个原始 UISegment 路径
            [viewPaths removeLastObject];
            // 添加使用位置拼接的正确路径
            [viewPaths addObject:[NSString stringWithFormat:@"UISegment[%@]", postion]];
            // 拼接完整路径信息
            NSString *newElementSelector = [viewPaths componentsJoinedByString:@"/"];
            return newElementSelector;
        }
    }
    #endif
    if (self.sensorsdata_enableAppClick) {
        return [SAVisualizedUtils viewPathForView:self atViewController:self.sensorsdata_viewController];
    } else {
        return nil;
    }
}

- (BOOL)sensorsdata_isFromWeb {
    return NO;
}

- (BOOL)sensorsdata_isListView {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"] || [NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"]) {
        return YES;
    }
#endif
    return NO;
}

- (NSString *)sensorsdata_screenName {
    // 解析 ReactNative 元素页面名称
    if ([SAAutoTrackUtils isKindOfRNView:self]) {
        NSDictionary *screenProperties = [self sensorsdata_RNElementScreenProperties];
        // 如果 ReactNative 页面信息为空，则使用 Native 的
        NSString *screenName = screenProperties[kSAEventPropertyScreenName];
        if (screenName) {
            return screenName;
        }
    }

    // 解析 Native 元素页面信息
    if (self.sensorsdata_viewController) {
        NSDictionary *autoTrackScreenProperties = [SAAutoTrackUtils propertiesWithViewController:self.sensorsdata_viewController];
        return autoTrackScreenProperties[kSAEventPropertyScreenName];
    }
    return nil;
}

- (NSString *)sensorsdata_title {
    // 处理 ReactNative 元素
    if ([SAAutoTrackUtils isKindOfRNView:self]) {
        NSDictionary *screenProperties = [self sensorsdata_RNElementScreenProperties];
        // 如果 ReactNative 的 screenName 不存在，则判断页面信息不存在，即使用 Native 逻辑
        if (screenProperties[kSAEventPropertyScreenName]) {
            return screenProperties[kSAEventPropertyTitle];
        }
    }

    // 处理 Native 元素
    if (self.sensorsdata_viewController) {
        NSDictionary *autoTrackScreenProperties = [SAAutoTrackUtils propertiesWithViewController:self.sensorsdata_viewController];
        return autoTrackScreenProperties[kSAEventPropertyTitle];
    }
    return nil;
}

#pragma mark SAVisualizedExtensionProperty
- (CGRect)sensorsdata_frame {
    CGRect showRect = [self convertRect:self.bounds toView:nil];
    if (self.superview) {
        // 计算可见区域
        CGRect visibleFrame = self.superview.sensorsdata_visibleFrame;
        return CGRectIntersection(showRect, visibleFrame);
    }
    return showRect;
}

- (CGRect)sensorsdata_visibleFrame {
    CGRect visibleFrame = [UIApplication sharedApplication].keyWindow.frame;
    if (self.superview) {
        CGRect superViewVisibleFrame = [self.superview sensorsdata_visibleFrame];
        visibleFrame = CGRectIntersection(visibleFrame, superViewVisibleFrame);
    }
    return visibleFrame;
}

@end


@implementation UIScrollView (SAElementPath)

- (CGRect)sensorsdata_visibleFrame {
    CGRect showRect = [self convertRect:self.bounds toView:nil];
    if (self.superview) {
        /* UIScrollView 单独处理
         UIScrollView 上子元素超出父视图部分不可见。
         普通 UIView 超出父视图，依然显示，但是超出部分不可交互，除非实现 hitTest
         */
        CGRect superViewValidFrame = [self.superview sensorsdata_visibleFrame];
        showRect = CGRectIntersection(showRect, superViewValidFrame);
    }
    return showRect;
}

@end

@implementation WKWebView (SAElementPath)

- (NSArray *)sensorsdata_subElements {
    NSArray *subElements = [SAVisualizedUtils analysisWebElementWithWebView:self];
    if (subElements.count > 0) {
        return subElements;
    }
    return [super sensorsdata_subElements];
}

@end


@implementation UIWindow (SAElementPath)

- (NSArray *)sensorsdata_subElements {
    if (!self.rootViewController) {
        return super.sensorsdata_subElements;
    }

    NSMutableArray *subElements = [NSMutableArray array];
    [subElements addObject:self.rootViewController];

    // 存在自定义弹框或浮层，位于 keyWindow
    NSArray <UIView *> *subviews = self.subviews;
    for (UIView *view in subviews) {
        if (view != self.rootViewController.view && view.sensorsdata_isVisible) {
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
            BOOL isFullScreenShow = CGPointEqualToPoint(rect.origin, CGPointZero) && CGSizeEqualToSize(rect.size, self.bounds.size);
            // keyWindow 上存在全屏显示可交互的 view，此时 rootViewController 内元素不可交互
            if (isFullScreenShow && view.userInteractionEnabled) {
                [subElements removeObject:self.rootViewController];
            }
        }
    }
    return subElements;
}

@end

@implementation SAJSTouchEventView (SAElementPath)

- (NSString *)sensorsdata_elementSelector {
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

#pragma mark - UIControl
@implementation UISwitch (SAElementPath)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UIStepper (SAElementPath)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UISegmentedControl (SAElementPath)

#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
- (NSString *)sensorsdata_itemPath {
    // 支持单个 UISegment 创建事件。UISegment 是 UIImageView 的私有子类，表示UISegmentedControl 单个选项的显示区域
    NSString *subPath = [NSString stringWithFormat:@"UISegment[%ld]", (long)self.selectedSegmentIndex];
    return [NSString stringWithFormat:@"%@/%@", super.sensorsdata_itemPath, subPath];
}

- (NSString *)sensorsdata_similarPath {
    return [NSString stringWithFormat:@"%@/UISegment[-]", super.sensorsdata_itemPath];
}

- (NSString *)sensorsdata_heatMapPath {
    NSString *subPath = [NSString stringWithFormat:@"UISegment[%ld]", (long)self.selectedSegmentIndex];
    return [NSString stringWithFormat:@"%@/%@", super.sensorsdata_heatMapPath, subPath];
}
#endif

@end

@implementation UISlider (SAElementPath)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UIPageControl (SAElementPath)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end


#pragma mark - TableView & Cell
@implementation UITableView (SAElementPath)

- (NSArray *)sensorsdata_subElements {
    NSArray *subviews = self.subviews;
    NSMutableArray *newSubviews = [NSMutableArray array];
    NSArray *visibleCells = self.visibleCells;
    for (UIView *view in subviews) {
        if ([view isKindOfClass:UITableViewCell.class]) {
            if ([visibleCells containsObject:view] && view.sensorsdata_isVisible) {
                [newSubviews addObject:view];
            }
        } else if (view.sensorsdata_isVisible) {
            [newSubviews addObject:view];
        }
    }
    return newSubviews;
}

@end

@implementation UITableViewHeaderFooterView (SAElementPath)

- (NSString *)sensorsdata_itemPath {
    UITableView *tableView = (UITableView *)self.superview;

    while (![tableView isKindOfClass:UITableView.class]) {
        tableView = (UITableView *)tableView.superview;
        if (!tableView) {
            return super.sensorsdata_itemPath;
        }
    }
    for (NSInteger i = 0; i < tableView.numberOfSections; i++) {
        if (self == [tableView headerViewForSection:i]) {
            return [NSString stringWithFormat:@"[SectionHeader][%ld]", (long)i];
        }
        if (self == [tableView footerViewForSection:i]) {
            return [NSString stringWithFormat:@"[SectionFooter][%ld]", (long)i];
        }
    }
    return super.sensorsdata_itemPath;
}

- (NSString *)sensorsdata_heatMapPath {
    UIView *currentTableView = self.superview;
    while (![currentTableView isKindOfClass:UITableView.class]) {
        currentTableView = currentTableView.superview;
        if (!currentTableView) {
            return super.sensorsdata_heatMapPath;
        }
    }

    UITableView *tableView = (UITableView *)currentTableView;
    for (NSInteger i = 0; i < tableView.numberOfSections; i++) {
        if (self == [tableView headerViewForSection:i]) {
            return [NSString stringWithFormat:@"[SectionHeader][%ld]", (long)i];
        }
        if (self == [tableView footerViewForSection:i]) {
            return [NSString stringWithFormat:@"[SectionFooter][%ld]", (long)i];
        }
    }
    return super.sensorsdata_heatMapPath;
}

@end


@implementation UICollectionView (SAElementPath)

- (NSArray *)sensorsdata_subElements {
    NSArray *subviews = self.subviews;
    NSMutableArray *newSubviews = [NSMutableArray array];
    NSArray *visibleCells = self.visibleCells;
    for (UIView *view in subviews) {
        if ([view isKindOfClass:UICollectionViewCell.class]) {
            if ([visibleCells containsObject:view] && view.sensorsdata_isVisible) {
                [newSubviews addObject:view];
            }
        } else if (view.sensorsdata_isVisible) {
            [newSubviews addObject:view];
        }
    }
    return newSubviews;
}

@end

@implementation UITableViewCell (SAElementPath)

- (NSIndexPath *)sensorsdata_IndexPath {
    UITableView *tableView = (UITableView *)[self superview];
    do {
        if ([tableView isKindOfClass:UITableView.class]) {
            NSIndexPath *indexPath = [tableView indexPathForCell:self];
            return indexPath;
        }
    } while ((tableView = (UITableView *)[tableView superview]));
    return nil;
}

#pragma mark SAAutoTrackViewPathProperty

- (NSString *)sensorsdata_itemPath {
    if (self.sensorsdata_IndexPath) {
        return [self sensorsdata_itemPathWithIndexPath:self.sensorsdata_IndexPath];
    }
    return [super sensorsdata_itemPath];
}

- (NSString *)sensorsdata_similarPath {
    if (self.sensorsdata_IndexPath) {
        return [self sensorsdata_similarPathWithIndexPath:self.sensorsdata_IndexPath];
    }
    return self.sensorsdata_itemPath;
}

- (NSString *)sensorsdata_heatMapPath {
    if (self.sensorsdata_IndexPath) {
        return [self sensorsdata_itemPathWithIndexPath:self.sensorsdata_IndexPath];
    }
    return [super sensorsdata_heatMapPath];
}

- (NSString *)sensorsdata_itemPathWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.row];
}

- (NSString *)sensorsdata_similarPathWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%@[%ld][-]", NSStringFromClass(self.class), (long)indexPath.section];
}

#pragma mark SAAutoTrackViewProperty
- (NSString *)sensorsdata_elementPosition {
    if (self.sensorsdata_IndexPath) {
        return [[NSString alloc] initWithFormat:@"%ld:%ld", (long)self.sensorsdata_IndexPath.section, (long)self.sensorsdata_IndexPath.row];
    }
    return nil;
}

- (BOOL)sensorsdata_isListView {
    return self.sensorsdata_elementPosition != nil;
}
@end


@implementation UICollectionViewCell (SAElementPath)

- (NSIndexPath *)sensorsdata_IndexPath {
    UICollectionView *collectionView = (UICollectionView *)[self superview];
    if ([collectionView isKindOfClass:UICollectionView.class]) {
        NSIndexPath *indexPath = [collectionView indexPathForCell:self];
        return indexPath;
    }
    return nil;
}

#pragma mark SAAutoTrackViewPathProperty
- (NSString *)sensorsdata_itemPath {
    if (self.sensorsdata_IndexPath) {
        return [self sensorsdata_itemPathWithIndexPath:self.sensorsdata_IndexPath];
    }
    return [super sensorsdata_itemPath];
}

- (NSString *)sensorsdata_similarPath {
    if (self.sensorsdata_IndexPath) {
        return [self sensorsdata_similarPathWithIndexPath:self.sensorsdata_IndexPath];
    } else {
        return super.sensorsdata_similarPath;
    }
}

- (NSString *)sensorsdata_heatMapPath {
    if (self.sensorsdata_IndexPath) {
        return [self sensorsdata_itemPathWithIndexPath:self.sensorsdata_IndexPath];
    }
    return [super sensorsdata_heatMapPath];
}

- (NSString *)sensorsdata_itemPathWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.item];
}

- (NSString *)sensorsdata_similarPathWithIndexPath:(NSIndexPath *)indexPath {
    SAViewElementInfo *elementInfo = [SAViewElementInfoFactory elementInfoWithView:self];
    if (!elementInfo.isSupportElementPosition) {
        return [self sensorsdata_itemPathWithIndexPath:indexPath];
    }
    return [NSString stringWithFormat:@"%@[%ld][-]", NSStringFromClass(self.class), (long)indexPath.section];
}

#pragma mark SAAutoTrackViewProperty
- (NSString *)sensorsdata_elementPosition {
    SAViewElementInfo *elementInfo = [SAViewElementInfoFactory elementInfoWithView:self];
    if (!elementInfo.isSupportElementPosition) {
        return nil;
    }

    if (self.sensorsdata_IndexPath) {
        return [[NSString alloc] initWithFormat:@"%ld:%ld", (long)self.sensorsdata_IndexPath.section, (long)self.sensorsdata_IndexPath.item];
    }
    return nil;
}

- (BOOL)sensorsdata_isListView {
    return self.sensorsdata_elementPosition != nil;
}

@end
