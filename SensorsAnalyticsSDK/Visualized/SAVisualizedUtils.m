//
// SAVisualizedUtils.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/3.
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

#import "SAVisualizedUtils.h"
#import "SAWebElementView.h"
#import "UIView+SAElementPath.h"
#import "SAVisualizedViewPathProperty.h"
#import "SAVisualizedObjectSerializerManager.h"
#import "SAConstants+Private.h"
#import "SAVisualizedManager.h"
#import "SAAutoTrackUtils.h"
#import "UIView+AutoTrack.h"
#import "SACommonUtility.h"
#import "SAJavaScriptBridgeManager.h"
#import "SALog.h"

/// 遍历查找页面最大层数，用于判断元素是否被覆盖
static NSInteger kSAVisualizedFindMaxPageLevel = 4;
typedef NSArray<UIView *>* (*SASortedRNSubviewsMethod)(UIView *, SEL);

/// RCTView 响应交互类型
typedef NS_ENUM(NSInteger, SARCTViewPointerEvents) {
    /// 0: 默认类型，优先使用子视图响应交互
    SARCTViewPointerEventsUnspecified = 0,
    /// 1: 自身以及子视图都不响应交互，所以不阻塞下层 view 交互
    SARCTViewPointerEventsNone,
    /// 2: 只让子视图响应交互，自身不可点击
    SARCTViewPointerEventsBoxNone,
    /// 3: 只有自身接收事件，子视图不可交互
    SARCTViewPointerEventsBoxOnly,
};

@implementation SAVisualizedUtils

#pragma mark Covered
+ (BOOL)isCoveredForView:(UIView *)view {
    NSArray <UIView *> *allOtherViews = [self findAllPossibleCoverViews:view hierarchyCount:kSAVisualizedFindMaxPageLevel];

    for (UIView *otherView in allOtherViews) {
        // 是否为 RN 的 View
        if ([self isKindOfRCTView:otherView]) {
            if ([self isCoveredOfRNView:view fromRNView:otherView]) {
                return YES;
            }
        } else if ([self isCoveredForView:view fromView:otherView]) {
            return YES;
        }
    }
    return NO;
}

/// 判断 RNView 是否遮挡底下的 view
/// @param view 被遮挡的 RNView
/// @param fromView 遮挡的 RNView
+ (BOOL)isCoveredOfRNView:(UIView *)view fromRNView:(UIView *)fromView {
    /* RCTView 默认重写了 hitTest:
     详情参照：https://github.com/facebook/react-native/blob/master/React/Views/RCTView.m
     针对 RN 部分框架或实现方式，设置 pointerEvents 并在 hitTest: 内判断处理，从而实现交互的穿透，不响应当前 RNView
     */
    SARCTViewPointerEvents pointerEvents = [self pointEventsWithRCTView:fromView];
    // RCTView 重写 hitTest: 并返回 nil，不阻塞底下元素交互
    if (pointerEvents == SARCTViewPointerEventsNone) {
        return NO;
    }
    // 遍历子视图判断是否存在坐标覆盖阻塞交互
    if (pointerEvents == SARCTViewPointerEventsBoxNone) {
        // 寻找完全遮挡 view 的子视图
        for (UIView *subView in fromView.subviews) {
            BOOL enableInteraction = [SAVisualizedUtils isVisibleForView:subView] && subView.userInteractionEnabled;
            BOOL isCovered = [self isCoveredForView:view fromView:subView];
            if (enableInteraction && isCovered) {
                return YES;
            }
        }
        return NO;
    }
    
    return [self isCoveredForView:view fromView:fromView];
}

/// 判断一个 view 是否被覆盖
/// @param view 当前 view
/// @param fromView 遮挡的 view
+ (BOOL)isCoveredForView:(UIView *)view fromView:(UIView *)fromView {
    CGRect rect = [view convertRect:view.bounds toView:nil];
    // 视图可能超出屏幕，计算 keywindow 交集，即在屏幕显示的有效区域
    CGRect keyWindowFrame = [UIApplication sharedApplication].keyWindow.frame;
    rect = CGRectIntersection(keyWindowFrame, rect);

    CGRect otherRect = [fromView convertRect:fromView.bounds toView:nil];
    return CGRectContainsRect(otherRect, rect);
}

// 根据层数，查询一个 view 所有可能覆盖的 view
+ (NSArray <UIView *> *)findAllPossibleCoverViews:(UIView *)view hierarchyCount:(NSInteger)count {
    NSMutableArray <UIView *> *allOtherViews = [NSMutableArray array];
    NSInteger index = count;
    UIView *currentView = view;
    while (index > 0 && currentView) {
        NSArray *allBrotherViews = [self findPossibleCoverAllBrotherViews:currentView];
        if (allBrotherViews.count > 0) {
            [allOtherViews addObjectsFromArray:allBrotherViews];
        }
        currentView = currentView.superview;
        index--;
    }
    return allOtherViews;
}

// 寻找一个 view 同级的后添加的 view
+ (NSArray *)findPossibleCoverAllBrotherViews:(UIView *)view {
    NSMutableArray <UIView *> *otherViews = [NSMutableArray array];
    UIView *superView = [view superview];
    NSArray *subviews = superView.subviews;
    
    if ([self isKindOfRCTView:superView]) {
        /* RCTView 默认重写了 hitTest:
         如果 pointerEvents = 0 或 2，会优先从按照 reactZIndex 排序后的数组 reactZIndexSortedSubviews 中逆序遍历查询用于交互的 view。所以这里，针对 pointerEvents = 0 或 2，也需要从 reactZIndexSortedSubviews 获取父试图的子视图，用于判断同级元素的交互遮挡。
         详情参照：https://github.com/facebook/react-native/blob/master/React/Views/RCTView.m
         */
        SARCTViewPointerEvents pointerEvents = [self pointEventsWithRCTView:superView];
        // RCTView 重写 hitTest: 并返回 nil，不阻塞底下元素交互
        if (pointerEvents != SARCTViewPointerEventsNone && pointerEvents != SARCTViewPointerEventsBoxOnly) {
            subviews = [self sortedRNSubviewsWithView:superView];
        }
    }
    if (subviews) {
        // 逆序遍历
        [subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if (obj == view) {
                *stop = YES;
            } else if ([self isVisibleForView:obj] && obj.userInteractionEnabled) { // userInteractionEnabled 为 YES 才有可能遮挡响应事件
                [otherViews addObject:obj];
            }
        }];
    }
    return otherViews;
}

/// view 是否可见
+ (BOOL)isVisibleForView:(UIView *)view {
    return view.alpha > 0.01 && !view.isHidden;
}

#pragma mark WebElement
+ (NSArray *)analysisWebElementWithWebView:(WKWebView <SAVisualizedExtensionProperty> *)webView {
    SAVisualizedWebPageInfo *webPageInfo = [[SAVisualizedObjectSerializerManager sharedInstance] readWebPageInfoWithWebView:webView];
    NSArray *webElementSources = webPageInfo.webElementSources;
    if (webElementSources.count == 0) {
        return nil;
    }
    
    // 元素去重，去除 id 相同的重复元素，并构建 model
    NSMutableArray<NSString *> *allNoRepeatElementIds = [NSMutableArray array];
    NSMutableArray<SAWebElementView *> *webElementArray = [NSMutableArray array];
    
    for (NSDictionary *pageData in webElementSources) {
        NSString *elementId = pageData[@"id"];
        if (elementId) {
            if ([allNoRepeatElementIds containsObject:elementId]) {
                continue;
            }
            [allNoRepeatElementIds addObject:elementId];
        }
        
        SAWebElementView *webElement = [[SAWebElementView alloc] initWithWebView:webView webElementInfo:pageData];
        if (webElement) {
            [webElementArray addObject:webElement];
        }
    }
    
    // 根据 level 升序排序
    [webElementArray sortUsingComparator:^NSComparisonResult(SAWebElementView *obj1,SAWebElementView *obj2) {
        if (obj1.level > obj2.level) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
    
    // 构建子元素数组
    for (SAWebElementView *webElement1 in [webElementArray copy]) {
        //当前元素是否嵌套子元素
        if (webElement1.jsSubElementIds.count == 0) {
            continue;
        }
        
        NSMutableArray *jsSubElements = [NSMutableArray arrayWithCapacity:webElement1.jsSubElementIds.count];
        // 根据子元素 id 查找对应子元素
        for (SAWebElementView *webElement2 in [webElementArray copy]) {
            // 如果 element2 是 element1 的子元素，则添加到 jsSubviews
            if ([webElement1.jsSubElementIds containsObject:webElement2.jsElementId]) {
                [jsSubElements addObject:webElement2];
                [webElementArray removeObject:webElement2];
            }
        }
        webElement1.jsSubviews = [jsSubElements copy];
    }
    return [webElementArray copy];
}

#pragma mark RNUtils

// 是否为RCTView 类型
+ (BOOL)isKindOfRCTView:(UIView *)view {
    Class rctViewClass = NSClassFromString(@"RCTView");
    return rctViewClass && [view isKindOfClass:rctViewClass];
}

+ (NSDictionary *)currentRNScreenVisualizeProperties {
    // 获取 RN 页面信息
    NSDictionary <NSString *, NSString *> *RNScreenInfo = nil;
    Class managerClass = NSClassFromString(@"SAReactNativeManager");
    SEL sharedInstanceSEL = NSSelectorFromString(@"sharedInstance");
    if ([managerClass respondsToSelector:sharedInstanceSEL]) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id manager = [managerClass performSelector:sharedInstanceSEL];
        SEL propsSEL = NSSelectorFromString(@"visualizeProperties");
        if ([manager respondsToSelector:propsSEL]) {
            RNScreenInfo = [manager performSelector:propsSEL];
        }
    #pragma clang diagnostic pop
    }
    return RNScreenInfo;
}

+ (BOOL)isRNCustomViewController:(UIViewController *)viewController {
    if (!viewController) {
        return NO;
    }
    Class managerClass = NSClassFromString(@"SAReactNativeManager");
    SEL sharedInstanceSEL = NSSelectorFromString(@"sharedInstance");
    if (managerClass && [managerClass respondsToSelector:sharedInstanceSEL]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

        // RN 框架中，部分弹出页面，是自定义的 ViewController，此时获取当前页面为 Native 页面名称
        NSArray *rnScreenNames = @[@"RCTModalHostViewController", @"RCTRedBoxExtraDataViewController", @"RCTWrapperViewController", @"RCTVideoPlayerViewController"];
        NSString *screenName = NSStringFromClass(viewController.class);
        return [rnScreenNames containsObject:screenName];
#pragma clang diagnostic pop
    }
    return NO;
}

// 获取 RCTView 按照 zIndex 排序后的子元素
+ (NSArray<UIView *> *)sortedRNSubviewsWithView:(UIView *)view {
    SEL sortedRNSubviewsSel = NSSelectorFromString(@"reactZIndexSortedSubviews");
    if (![view respondsToSelector:sortedRNSubviewsSel]) {
        return view.subviews;
    }
    SASortedRNSubviewsMethod method = (SASortedRNSubviewsMethod)[view methodForSelector:sortedRNSubviewsSel];
    return method(view, sortedRNSubviewsSel);
}

+ (BOOL)isInteractiveEnabledRNView:(UIView *)view {
    /* RCTView 默认重写了 hitTest:，对应做兼容处理
     详情参照：https://github.com/facebook/react-native/blob/master/React/Views/RCTView.m
     */
    // 当前 view 的父视图是否禁用子视图交互
    if (view.superview.sensorsdata_isDisableRNSubviewsInteractive) {
        view.sensorsdata_isDisableRNSubviewsInteractive = YES;
        return NO;
    }
    
    if (![self isKindOfRCTView:view]) {
        return YES;
    }
  
    // 设置交互状态
    SARCTViewPointerEvents pointerEvents = [self pointEventsWithRCTView:view];
    // None 和 BoxOnly 都禁用子视图交互
    BOOL isEventsNone = pointerEvents == SARCTViewPointerEventsNone;
    BOOL isEventsBoxOnly = pointerEvents == SARCTViewPointerEventsBoxOnly;
    view.sensorsdata_isDisableRNSubviewsInteractive = isEventsNone || isEventsBoxOnly;
    
    // EventsNone 和 EventsBoxNone 时，自身不可交互
    if (pointerEvents == SARCTViewPointerEventsNone || pointerEvents == SARCTViewPointerEventsBoxNone) {
        return NO;
    }
    
    return YES;
}

/// 获取当前 RCTView 的交互类型
+ (SARCTViewPointerEvents)pointEventsWithRCTView:(UIView *)view {
    if (![self isKindOfRCTView:view]) {
        return SARCTViewPointerEventsUnspecified;
    }
    
    SARCTViewPointerEvents pointerEvents = SARCTViewPointerEventsUnspecified;
    @try {
        pointerEvents = [[view valueForKey:@"pointerEvents"] integerValue];
    } @catch (NSException *exception) {
        SALogWarn(@"%@ error: %@", self, exception);
    }
    return pointerEvents;
}

#pragma mark keyWindow
/// 获取当前有效的 keyWindow
+ (UIWindow *)currentValidKeyWindow {
    UIWindow *keyWindow = nil;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in windowScene.windows) {
                    // 可能创建的 window 被隐藏
                    if (![self isVisibleForView:window]) {
                        continue;
                    }
                    // iOS 13 及以上，可能动态设置其他 window 为 keyWindow，此时直接使用此 keyWindow
                    if (window.isKeyWindow) {
                        return window;
                    }
                    // 获取 windowScene.windows 中第一个 window
                    if (!keyWindow) {
                        keyWindow = window;
                    }
                }
                break;
            }
        }
    }
#endif
    return keyWindow ?: [self topWindow];
}

+ (UIWindow *)topWindow {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    NSArray<UIWindow *> *allWindows = [UIApplication sharedApplication].windows;

    // 如果 windows 未包含 keyWindow，可能是 iOS13 以下系统弹出 UIAlertView 等场景，此时忽略 UIAlertView 所在 window
    if ([allWindows containsObject:keyWindow]) {
        return keyWindow;
    }

    // 逆序遍历，获取最上层全屏可见 window
    CGSize fullScreenSize = [UIScreen mainScreen].bounds.size;
    for (UIWindow *window in [allWindows reverseObjectEnumerator]) {
        if ([window isMemberOfClass:UIWindow.class] && CGSizeEqualToSize(fullScreenSize, window.frame.size) && [self isVisibleForView:window]) {
            return window;
        }
    }
    return nil;
}

#pragma mark viewTree
+ (BOOL)isAutoTrackAppClickWithControl:(UIControl *)control {
    // 部分控件，暂不支持  $AppClick 全埋点采集
    if ([control isKindOfClass:UIDatePicker.class]) {
        return NO;
    }
    
    BOOL userInteractionEnabled = control.userInteractionEnabled;
    BOOL enabled = control.enabled;
    UIControlEvents appClickEvents = UIControlEventTouchUpInside | UIControlEventValueChanged;
    
    // UISegmentedControl 只响应 UIControlEventValueChanged 和 UIControlEventPrimaryActionTriggered 全埋点
    if ([control isKindOfClass:UISegmentedControl.class]) {
        appClickEvents = UIControlEventValueChanged;
    }
    
    if (@available(iOS 9.0, *)) {
        appClickEvents = appClickEvents | UIControlEventPrimaryActionTriggered;
    }
    BOOL containEvents = (appClickEvents & control.allControlEvents) != 0;
    if (containEvents && userInteractionEnabled && enabled) { // 可点击
        return YES;
    }
    return NO;
}

/// 需要忽略子元素
+ (BOOL)isIgnoreSubviewsWithView:(UIView *)view {
    if (!view) {
        return NO;
    }

    /* 类名黑名单，忽略子元素
     _UITextFieldCanvasView 和 _UISearchTextFieldCanvasView 分别是 iOS13 和 iOS14 的 UISearchBar 内嵌 View
     */
    NSArray <NSString *>*blacklistClassName = @[@"UISegment", @"UITabBarButton", @"_UITextFieldCanvasView", @"_UISearchTextFieldCanvasView"];
    NSString *className = NSStringFromClass(view.class);
    if ([blacklistClassName containsObject:className]) {
        return YES;
    }

    // 特殊控件作为整体，不必遍历子元素
    if ([view isKindOfClass:UITextView.class]) {
        return YES;
    }

    // 一般作为普通 view 并添加点击事件，继续遍历子元素
    if (![view isKindOfClass:UIControl.class]) {
        return NO;
    }

    // 部分独立可点击元素，作为整体，不需要再向下遍历，忽略子元素
    NSArray <Class > *blacklistClass = @[UIButton.class, UISwitch.class, UIStepper.class, UISlider.class, UIPageControl.class];
    if ([blacklistClass containsObject:view.class]) {
        return YES;
    }

    return NO;
}

#pragma mark Utils
// 对 view 截图
+ (UIImage *)screenshotWithView:(UIView *)view {
    if (![view isKindOfClass:UIView.class]) {
        return nil;
    }
    UIImage *screenshotImage = nil;
    @try {
        CGSize size = view.bounds.size;
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
        CGRect rect = view.bounds;
        // drawViewHierarchyInRect:afterScreenUpdates: 截取一个UIView或者其子类中的内容，并且以位图的形式（bitmap）保存到UIImage中
        // afterUpdates 参数表示是否在所有效果应用在视图上了以后再获取快照
        [view drawViewHierarchyInRect:rect afterScreenUpdates:NO];
        screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } @catch (NSException *exception) {
        SALogError(@"screenshot fail，error %@: %@", self, exception);
    }
    return screenshotImage;
}

+ (BOOL)isSupportCallJSWithWebView:(WKWebView *)webview {
    WKUserContentController *contentController = webview.configuration.userContentController;
    NSArray<WKUserScript *> *userScripts = contentController.userScripts;

    // 判断基于 UA 的老版打通
    NSString *currentUserAgent = [SACommonUtility currentUserAgent];
    if ([currentUserAgent containsString:@"sa-sdk-ios"]) {
        return YES;
    }

    // 判断新版打通
    __block BOOL isContainJavaScriptBridge = NO;
    [userScripts enumerateObjectsUsingBlock:^(WKUserScript *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj.source containsString:kSAJSBridgeServerURL]) {
            isContainJavaScriptBridge = YES;
            *stop = YES;
        }
    }];

    return isContainJavaScriptBridge;
}

@end


#pragma mark -

@implementation SAVisualizedUtils (ViewPath)

+ (BOOL)isIgnoredViewPathForViewController:(UIViewController *)viewController {
    BOOL isEnableVisualized =  [[SAVisualizedManager defaultManager] isVisualizeWithViewController:viewController];
    return !isEnableVisualized;
}

+ (BOOL)isIgnoredItemPathWithView:(UIView *)view {
    NSString *className = NSStringFromClass(view.class);
    /* 类名黑名单，忽略元素相对路径
     为了兼容不同系统、不同状态下的路径匹配，忽略区分元素的路径
     */
    NSArray <NSString *>*ignoredItemClassNames = @[@"UITableViewWrapperView", @"UISegment", @"_UISearchBarFieldEditor", @"UIFieldEditor"];
    return [ignoredItemClassNames containsObject:className];
}

/// 获取模糊路径
+ (NSString *)viewSimilarPathForView:(UIView *)view atViewController:(UIViewController *)viewController {
    if ([self isIgnoredViewPathForViewController:viewController]) {
        return nil;
    }

    NSMutableArray *viewPathArray = [NSMutableArray array];
    BOOL isContainSimilarPath = NO;

    do {
        if (isContainSimilarPath) { // 防止 cell 等列表嵌套，被拼上多个 [-]
            if (view.sensorsdata_itemPath) {
                [viewPathArray addObject:view.sensorsdata_itemPath];
            }
        } else {
            NSString *currentSimilarPath = view.sensorsdata_similarPath;
            if (currentSimilarPath) {
                [viewPathArray addObject:currentSimilarPath];
                if ([currentSimilarPath containsString:@"[-]"]) {
                    isContainSimilarPath = YES;
                }
            }
        }
    } while ((view = (id)view.nextResponder) && [view isKindOfClass:UIView.class]);

    if ([view isKindOfClass:UIAlertController.class]) {
        UIViewController<SAAutoTrackViewPathProperty> *viewController = (UIViewController<SAAutoTrackViewPathProperty> *)view;
        [viewPathArray addObject:viewController.sensorsdata_similarPath];
    }

    NSString *viewPath = [[[viewPathArray reverseObjectEnumerator] allObjects] componentsJoinedByString:@"/"];

    return viewPath;
}

/// 当前 view 所在同类页面序号
+ (NSInteger)pageIndexWithView:(UIView *)view {
    if (!view) {
        return -1;
    }
    
    UIResponder *next = view;
    do {
        // 非 UIViewController，直接找 nextResponder
        if (![next isKindOfClass:UIViewController.class]) {
            continue;
        }

        UIViewController *vc = (UIViewController *)next;
        // 针对 UIAlertController，需要计算 presentingViewController 所在序号
        if ([vc isKindOfClass:UIAlertController.class]) {
            next = vc.presentingViewController;
            break;
        }

        //当前已经是 UIViewController，直接退出
        break;
    } while ((next = next.nextResponder));

    UIViewController *viewController = [next isKindOfClass:UIViewController.class] ? (UIViewController *)next : nil;
    return [self pageIndexWithViewController:viewController];
}

+ (NSInteger)pageIndexWithViewController:(UIViewController *)viewController {
    UIViewController *parentViewController = viewController.parentViewController;
    if (!viewController || !parentViewController || viewController.parentViewController.childViewControllers.count == 1) {
        return -1;
    }

    // UINavigationController 和 UITabBarController 已经获取了当前 topViewController 和 selectedViewController，不再需要匹配 pageIndex
    if ([parentViewController isKindOfClass:UINavigationController.class] || [parentViewController isKindOfClass:UITabBarController.class] || [parentViewController isKindOfClass:UISplitViewController.class]) {
        return -1;
    }

    NSInteger count = 0;
    NSInteger index = -1;
    NSString *screenName = NSStringFromClass(viewController.class);
    for (UIViewController *vc in parentViewController.childViewControllers) {
        if ([screenName isEqualToString:NSStringFromClass(vc.class)]) {
            count++;
        }
        if (vc == viewController) {
            index = count - 1;
        }
    }
    return count == 1 ? -1 : index;
}

@end


