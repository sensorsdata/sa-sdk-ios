//
// UIView+SAElementPath.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
#import "UIView+SAVisualizedViewPath.h"
#import "UIView+SAAutoTrack.h"
#import "UIViewController+SAAutoTrack.h"
#import "UIViewController+SAElementPath.h"
#import "SAVisualizedUtils.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAViewElementInfoFactory.h"
#import "UIView+SAItemPath.h"
#import "UIView+SASimilarPath.h"
#import "UIView+SAElementPosition.h"
#import "UIView+SAInternalProperties.h"
#import "UIView+SARNView.h"
#import "SAUIProperties.h"

typedef BOOL (*SAClickableImplementation)(id, SEL, UIView *);

// NB If you add any more fingerprint methods, increment this.
static int kSAFingerprintVersion = 1;

static void *const kSAIsDisableRNSubviewsInteractivePropertyName = (void *)&kSAIsDisableRNSubviewsInteractivePropertyName;

#pragma mark - UIView
@implementation UIView (SAVisualizedViewPath)


- (int)jjf_fingerprintVersion {
	return kSAFingerprintVersion;
}

// 判断一个 view 是否显示
- (BOOL)sensorsdata_isVisible {
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
    BOOL isRNView = [self isSensorsdataRNView];
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
    
    // RN 已禁用了子视图交互
    if (![SAVisualizedUtils isInteractiveEnabledRNView:self]) {
        return NO;
    }

    /* 先判断 RN 是否可点击，再判断 Native 屏蔽
     RCTSwitch 和 RCTSlider 等元素，由 RN 触发元素点击，并设置在 Native 屏蔽
     */
    if ([self sensorsdata_clickableForRNView]) {
        return YES;
    }

    // 是否被忽略或黑名单屏蔽
    if (self.sensorsdata_isIgnored) {
        return NO;
    }
    UIViewController *viewController = self.sensorsdata_viewController;
    if (viewController && viewController.sensorsdata_isIgnored) {
        return NO;
    }

    // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)[self superview];
        if (![segmentedControl isKindOfClass:UISegmentedControl.class]) {
            return NO;
        }
        // 可能是 RN 框架 中 RCTSegmentedControl 内嵌 UISegment，如果为 NO，再执行一次 RN 的可点击判断
        BOOL clickable = [SAVisualizedUtils isAutoTrackAppClickWithControl:segmentedControl];
        if (clickable){
            return YES;
        }
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
    if ([self isSensorsdataRNView]) {
        return [self.accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    return self.sensorsdata_elementContent;
}

/// 元素子视图
- (NSArray *)sensorsdata_subElements {
    // 部分元素，忽略子视图
    if ([SAVisualizedUtils isIgnoreSubviewsWithView:self]) {
        return nil;
    }

    NSMutableArray *newSubViews = [NSMutableArray array];
    
    // 构建 flutter 元素
    // flutter 页面判断
    if (NSClassFromString(@"FlutterView") && [self isKindOfClass:NSClassFromString(@"FlutterView")]) {
        // FlutterView 上可能嵌套 Native 元素或 webView
        NSArray *subElements = [SAVisualizedUtils analysisFlutterElementWithFlutterView:self];
        if (subElements.count > 0) {
            [newSubViews addObjectsFromArray:subElements];
        }
    }
    
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
    
    NSArray<UIView *>* subViews = self.subviews;
    // 针对 RCTView，获取按照 zIndex 排序后的子元素
    if ([SAVisualizedUtils isKindOfRCTView:self]) {
        subViews = [SAVisualizedUtils sortedRNSubviewsWithView:self];
    }
    for (UIView *view in subViews) {
        if (view.sensorsdata_isVisible) {
            [newSubViews addObject:view];
        }
    }
    return newSubViews;
}

- (BOOL)sensorsdata_isFromWeb {
    return NO;
}

- (BOOL)sensorsdata_isListView {
    // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"] || [NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"]) {
        return YES;
    }
    return NO;
}

- (NSString *)sensorsdata_platform {
    return @"ios";
}

- (NSString *)sensorsdata_screenName {
    // 解析 ReactNative 元素页面名称
    if ([self isSensorsdataRNView]) {
        NSDictionary *screenProperties = [self sensorsdata_RNElementScreenProperties];
        // 如果 ReactNative 页面信息为空，则使用 Native 的
        NSString *screenName = screenProperties[kSAEventPropertyScreenName];
        if (screenName) {
            return screenName;
        }
    }

    // 解析 Native 元素页面信息
    if (self.sensorsdata_viewController) {
        NSDictionary *autoTrackScreenProperties = [SAUIProperties propertiesWithViewController:self.sensorsdata_viewController];
        return autoTrackScreenProperties[kSAEventPropertyScreenName];
    }
    return nil;
}

- (NSString *)sensorsdata_title {
    // 处理 ReactNative 元素
    if ([self isSensorsdataRNView]) {
        NSDictionary *screenProperties = [self sensorsdata_RNElementScreenProperties];
        // 如果 ReactNative 的 screenName 不存在，则判断页面信息不存在，即使用 Native 逻辑
        if (screenProperties[kSAEventPropertyScreenName]) {
            return screenProperties[kSAEventPropertyTitle];
        }
    }

    // 处理 Native 元素
    if (self.sensorsdata_viewController) {
        NSDictionary *autoTrackScreenProperties = [SAUIProperties propertiesWithViewController:self.sensorsdata_viewController];
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

- (CGRect)sensorsdata_visibleFrame NS_EXTENSION_UNAVAILABLE("VisualizedAutoTrack not supported for iOS extensions.") {
    CGRect visibleFrame = [UIApplication sharedApplication].keyWindow.frame;
    /* 如果 clipsToBounds = YES，剪裁超出父视图范围的子视图部分，即子视图超出父视图部分不可见
     UIScrollView 中，它的默认值是 YES，也就是说默认裁剪的
     所以 clipsToBounds = YES，当前视图的可见有效范围只有自身尺寸
     */
    if (self.clipsToBounds) {
        visibleFrame = [self convertRect:self.bounds toView:nil];
    }
    if (self.superview) {
        CGRect superViewVisibleFrame = [self.superview sensorsdata_visibleFrame];
        visibleFrame = CGRectIntersection(visibleFrame, superViewVisibleFrame);
    }
    return visibleFrame;
}

- (BOOL)sensorsdata_isDisableRNSubviewsInteractive {
    return [objc_getAssociatedObject(self, kSAIsDisableRNSubviewsInteractivePropertyName) boolValue];
}

- (void)setSensorsdata_isDisableRNSubviewsInteractive:(BOOL)sensorsdata_isDisableRNSubviewsInteractive {
    objc_setAssociatedObject(self, kSAIsDisableRNSubviewsInteractivePropertyName, @(sensorsdata_isDisableRNSubviewsInteractive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation WKWebView (SAVisualizedViewPath)

- (NSArray *)sensorsdata_subElements {
    NSArray *subElements = [SAVisualizedUtils analysisWebElementWithWebView:self];
    if (subElements.count > 0) {
        return subElements;
    }
    return [super sensorsdata_subElements];
}

@end


@implementation UIWindow (SAVisualizedViewPath)

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
            if ([NSStringFromClass(view.class) isEqualToString:@"UITransitionView"]) {
                continue;
            }
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

@implementation SAVisualizedElementView (SAElementPath)

#pragma mark SAVisualizedViewPathProperty
- (NSString *)sensorsdata_title {
    return self.title;
}

- (NSString *)sensorsdata_screenName {
    return self.screenName;
}

- (NSString *)sensorsdata_elementValidContent {
    return self.elementContent;
}

- (CGRect)sensorsdata_frame {
    return self.frame;
}

- (BOOL)sensorsdata_enableAppClick {
    return self.enableAppClick;
}

- (NSArray *)sensorsdata_subElements {
    if (self.subElements.count > 0) {
        return self.subElements;
    }
    return [super sensorsdata_subElements];
}

- (BOOL)sensorsdata_isFromWeb {
    return NO;
}

- (BOOL)sensorsdata_isListView {
    return self.isListView;
}

- (NSString *)sensorsdata_platform {
    return self.platform;
}

- (NSString *)sensorsdata_elementPath {
    return self.elementPath;
}

- (NSString *)sensorsdata_elementPosition {
    return self.elementPosition;
}

@end


@implementation SAWebElementView (SAElementPath)
- (BOOL)sensorsdata_isFromWeb {
    return YES;
}

- (NSString *)sensorsdata_elementSelector {
    return self.elementSelector;
}

@end

#pragma mark - UIControl
@implementation UISwitch (SAVisualizedViewPath)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UIStepper (SAVisualizedViewPath)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UISlider (SAVisualizedViewPath)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UIPageControl (SAVisualizedViewPath)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end


#pragma mark - TableView & Cell
@implementation UITableView (SAVisualizedViewPath)

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

@implementation UICollectionView (SAVisualizedViewPath)

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

@implementation UITableViewCell (SAVisualizedViewPath)

- (BOOL)sensorsdata_isListView {
    return self.sensorsdata_elementPosition != nil;
}
@end


@implementation UICollectionViewCell (SAVisualizedViewPath)

- (BOOL)sensorsdata_isListView {
    return self.sensorsdata_elementPosition != nil;
}

@end
