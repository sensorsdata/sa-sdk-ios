//
// SAVisualizedUtils.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/3.
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

#import "SAVisualizedUtils.h"
#import "SAJSTouchEventView.h"
#import "SAVisualizedViewPathProperty.h"
#import "SAJSONUtil.h"
#import "SAVisualizedObjectSerializerManger.h"
#import "SALog.h"

/// 遍历查找页面最大层数，用于判断元素是否被覆盖
static NSInteger kSAVisualizedFindMaxPageLevel = 4;

@implementation SAVisualizedUtils


+ (BOOL)isCoveredForView:(UIView *)view {
    NSArray <UIView *> *allOtherViews = [self findAllPossibleCoverViews:view hierarchyCount:kSAVisualizedFindMaxPageLevel];

    for (UIView *otherView in allOtherViews) {
        // 是否为 RN 的 View
        if ([SAVisualizedUtils isKindOfRNView:otherView]) {
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
    @try {
        /* RCTView 默认重写了 hitTest:
         详情参照：https://github.com/facebook/react-native/blob/master/React/Views/RCTView.m
         针对 RN 部分框架或实现方式，设置 pointerEvents 并在 hitTest: 内判断处理，从而实现交互的穿透，不响应当前 RNView
         */
        NSInteger pointerEvents = [[fromView valueForKey:@"pointerEvents"] integerValue];
        // RCTView 重写 hitTest: 并返回 nil，不阻塞底下元素交互
        if (pointerEvents == 1) {
            return NO;
        }
        // 遍历子视图判断是否存在坐标覆盖阻塞交互
        if (pointerEvents == 2) {
            // 寻找完全遮挡 view 的子视图
            for (UIView *subView in fromView.subviews) {
                BOOL enableInteraction = subView.alpha >= 0.01 && !subView.hidden && subView.userInteractionEnabled;
                BOOL isCovered = [self isCoveredForView:view fromView:subView];
                if (enableInteraction && isCovered) {
                    return YES;
                }
            }
            return NO;
        }
    } @catch (NSException *exception) {
        SALogDebug(@"%@ error: %@", self, exception);
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

+ (BOOL)isKindOfRNView:(UIView *)view {
    Class RNViewClass = NSClassFromString(@"RCTView");
    return RNViewClass && [view isKindOfClass:RNViewClass];
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
    if (superView) {
        // 逆序遍历
        [superView.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
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

+ (NSArray *)analysisWebElementWithWebView:(WKWebView <SAVisualizedExtensionProperty> *)webView {
    SAVisualizedWebPageInfo *webPageInfo = [[SAVisualizedObjectSerializerManger sharedInstance] readWebPageInfoWithWebView:webView];
    NSArray *webPageDatas = webPageInfo.elementSources;
    if (webPageDatas.count == 0) {
        return nil;
    }

    // 元素去重，去除 id 相同的重复元素
    NSMutableArray <NSString *> *allNoRepeatElementIds = [NSMutableArray array];
    NSMutableArray <SAJSTouchEventView *> *touchViewArray = [NSMutableArray array];
    for (NSDictionary *pageData in webPageDatas) {
        NSString *elementId = pageData[@"id"];
        if (elementId) {
            if ([allNoRepeatElementIds containsObject:elementId]) {
                continue;
            }
            [allNoRepeatElementIds addObject:elementId];
        }

        SAJSTouchEventView *touchView = [[SAJSTouchEventView alloc] initWithWebView:webView webElementInfo:pageData];
        if (touchView) {
            [touchViewArray addObject:touchView];
        }
    }

    // 构建子元素数组
    for (SAJSTouchEventView *touchView1 in [touchViewArray copy]) {
        //当前元素嵌套子元素
        if (touchView1.jsSubElementIds.count > 0) {
            NSMutableArray *jsSubElement = [NSMutableArray arrayWithCapacity:touchView1.jsSubElementIds.count];
            // 根据子元素 id 查找对应子元素
            for (NSString *elementId in touchView1.jsSubElementIds) {
                for (SAJSTouchEventView *touchView2 in [touchViewArray copy]) {
                    if ([elementId isEqualToString:touchView2.jsElementId]) {
                        [jsSubElement addObject:touchView2];
                        [touchViewArray removeObject:touchView2];
                    }
                }
            }
            touchView1.jsSubviews = [jsSubElement copy];
        }
    }
    return [touchViewArray copy];
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

/// 获取当前有效的 keyWindow
+ (UIWindow *)currentValidKeyWindow {
    UIWindow *keyWindow = [self currentKeyWindow];
    // 判断 keyWindow 是否显示
    if ([self isVisibleForView:keyWindow]) {
        return keyWindow;
    }

    __block UIWindow *validWindow = nil;
    // 逆序遍历，获取最上层全屏 window
    [[UIApplication sharedApplication].windows enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGSize fullScreenSize = [UIScreen mainScreen].bounds.size;
        if ([obj isMemberOfClass:UIWindow.class] && CGSizeEqualToSize(fullScreenSize, obj.frame.size) && [self isVisibleForView:obj]) {
            validWindow = obj;
            *stop = YES;
        }
    }];
    return validWindow;
}

// 获取当前 keyWindow
+ (UIWindow *)currentKeyWindow {
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
                        keyWindow = window;
                        break;
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
    return keyWindow ?: [UIApplication sharedApplication].keyWindow;
}

@end
