//
// SAUIProperties.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/29.
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

#import "SAUIProperties.h"
#import "UIView+SAViewPath.h"
#import "SACommonUtility.h"
#import "SAConstants+Private.h"
#import "UIView+SAElementID.h"
#import "UIView+SAElementType.h"
#import "UIView+SAElementContent.h"
#import "UIView+SAElementPosition.h"
#import "UIView+SAInternalProperties.h"
#import "UIView+SensorsAnalytics.h"
#import "UIViewController+SAInternalProperties.h"
#import "SAValidator.h"
#import "SAModuleManager.h"
#import "SALog.h"

@implementation SAUIProperties

+ (NSInteger)indexWithResponder:(UIResponder *)responder {
    NSString *classString = NSStringFromClass(responder.class);
    NSInteger index = -1;
    NSArray<UIResponder *> *brothersResponder = [self siblingElementsOfResponder:responder];

    for (UIResponder *res in brothersResponder) {
        if ([classString isEqualToString:NSStringFromClass(res.class)]) {
            index ++;
        }
        if (res == responder) {
            break;
        }
    }

    /* 序号说明
     -1：nextResponder 不是父视图或同类元素，比如 controller.view，涉及路径不带序号
     >=0：元素序号
     */
    return index;
}

/// 寻找所有兄弟元素
+ (NSArray <UIResponder *> *)siblingElementsOfResponder:(UIResponder *)responder {
    if ([responder isKindOfClass:UIView.class]) {
        UIResponder *next = [responder nextResponder];
        if ([next isKindOfClass:UIView.class]) {
            NSArray<UIView *> *subViews = [(UIView *)next subviews];
            if ([next isKindOfClass:UISegmentedControl.class]) {
                // UISegmentedControl 点击之后，subviews 顺序会变化，需要根据坐标排序才能得到准确序号
                NSArray<UIView *> *brothers = [subViews sortedArrayUsingComparator:^NSComparisonResult (UIView *obj1, UIView *obj2) {
                    if (obj1.frame.origin.x > obj2.frame.origin.x) {
                        return NSOrderedDescending;
                    } else {
                        return NSOrderedAscending;
                    }
                }];
                return brothers;
            }
            return subViews;
        }
    } else if ([responder isKindOfClass:UIViewController.class]) {
        return [(UIViewController *)responder parentViewController].childViewControllers;
    }
    return nil;
}

+ (BOOL)isIgnoredItemPathWithView:(UIView *)view {
    NSString *className = NSStringFromClass(view.class);
    /* 类名黑名单，忽略元素相对路径
     为了兼容不同系统、不同状态下的路径匹配，忽略区分元素的路径
     */
    NSArray <NSString *>*ignoredItemClassNames = @[@"UITableViewWrapperView", @"UISegment", @"_UISearchBarFieldEditor", @"UIFieldEditor"];
    return [ignoredItemClassNames containsObject:className];
}

+ (NSString *)elementPathForView:(UIView *)view atViewController:(UIViewController *)viewController {
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
        UIAlertController<SAUIViewPathProperties> *viewController = (UIAlertController<SAUIViewPathProperties> *)view;
        [viewPathArray addObject:viewController.sensorsdata_similarPath];
    }

    NSString *viewPath = [[[viewPathArray reverseObjectEnumerator] allObjects] componentsJoinedByString:@"/"];

    return viewPath;
}

+ (UIViewController *)findNextViewControllerByResponder:(UIResponder *)responder {
    UIResponder *next = responder;
    do {
        if (![next isKindOfClass:UIViewController.class]) {
            continue;
        }
        UIViewController *vc = (UIViewController *)next;
        if ([vc isKindOfClass:UINavigationController.class]) {
            return [self findNextViewControllerByResponder:[(UINavigationController *)vc topViewController]];
        } else if ([vc isKindOfClass:UITabBarController.class]) {
            return [self findNextViewControllerByResponder:[(UITabBarController *)vc selectedViewController]];
        }

        UIViewController *parentVC = vc.parentViewController;
        if (!parentVC) {
            break;
        }
        if ([parentVC isKindOfClass:UINavigationController.class] ||
            [parentVC isKindOfClass:UITabBarController.class] ||
            [parentVC isKindOfClass:UIPageViewController.class] ||
            [parentVC isKindOfClass:UISplitViewController.class]) {
            break;
        }
    } while ((next = next.nextResponder));
    return [next isKindOfClass:UIViewController.class] ? (UIViewController *)next : nil;
}

+ (UIViewController *)currentViewController NS_EXTENSION_UNAVAILABLE("VisualizedAutoTrack not supported for iOS extensions.") {
    __block UIViewController *currentViewController = nil;
    void (^ block)(void) = ^{
        UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
        currentViewController = [SAUIProperties findCurrentViewControllerFromRootViewController:rootViewController isRoot:YES];
    };

    [SACommonUtility performBlockOnMainThread:block];
    return currentViewController;
}

+ (UIViewController *)findCurrentViewControllerFromRootViewController:(UIViewController *)viewController isRoot:(BOOL)isRoot {
    if ([self canFindPresentedViewController:viewController.presentedViewController]) {
         return [self findCurrentViewControllerFromRootViewController:viewController.presentedViewController isRoot:NO];
     }

    if ([viewController isKindOfClass:[UITabBarController class]]) {
        return [self findCurrentViewControllerFromRootViewController:[(UITabBarController *)viewController selectedViewController] isRoot:NO];
    }

    if ([viewController isKindOfClass:[UINavigationController class]]) {
        // 根视图为 UINavigationController
        UIViewController *topViewController = [(UINavigationController *)viewController topViewController];
        return [self findCurrentViewControllerFromRootViewController:topViewController isRoot:NO];
    }

    if (viewController.childViewControllers.count > 0) {
        if (viewController.childViewControllers.count == 1 && isRoot) {
            return [self findCurrentViewControllerFromRootViewController:viewController.childViewControllers.firstObject isRoot:NO];
        } else {
            __block UIViewController *currentViewController = viewController;
            //从最上层遍历（逆序），查找正在显示的 UITabBarController 或 UINavigationController 类型的
            // 是否包含 UINavigationController 或 UITabBarController 类全屏显示的 controller
            [viewController.childViewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                // 判断 obj.view 是否加载，如果尚未加载，调用 obj.view 会触发 viewDidLoad，可能影响客户业务
                if (obj.isViewLoaded) {
                    CGPoint point = [obj.view convertPoint:CGPointZero toView:nil];
                    CGSize windowSize = obj.view.window.bounds.size;
                   // 正在全屏显示
                    BOOL isFullScreenShow = !obj.view.hidden && obj.view.alpha > 0.01 && CGPointEqualToPoint(point, CGPointZero) && CGSizeEqualToSize(obj.view.bounds.size, windowSize);
                   // 判断类型
                    BOOL isStopFindController = [obj isKindOfClass:UINavigationController.class] || [obj isKindOfClass:UITabBarController.class];
                    if (isFullScreenShow && isStopFindController) {
                        currentViewController = [self findCurrentViewControllerFromRootViewController:obj isRoot:NO];
                        *stop = YES;
                    }
                }
            }];
            return currentViewController;
        }
    } else if ([viewController respondsToSelector:NSSelectorFromString(@"contentViewController")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        UIViewController *tempViewController = [viewController performSelector:NSSelectorFromString(@"contentViewController")];
#pragma clang diagnostic pop
        if (tempViewController) {
            return [self findCurrentViewControllerFromRootViewController:tempViewController isRoot:NO];
        }
    }
    return viewController;
}

+ (BOOL)canFindPresentedViewController:(UIViewController *)viewController {
    if (!viewController) {
        return NO;
    }
    if ([viewController isKindOfClass:UIAlertController.class]) {
        return NO;
    }
    if ([@"_UIContextMenuActionsOnlyViewController" isEqualToString:NSStringFromClass(viewController.class)]) {
        return NO;
    }
    return YES;
}

+ (NSDictionary *)propertiesWithView:(UIView *)view viewController:(UIViewController *)viewController {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    
    viewController = viewController ? : view.sensorsdata_viewController;
    NSDictionary *dic = [self propertiesWithViewController:viewController];
    [properties addEntriesFromDictionary:dic];

    properties[kSAEventPropertyElementId] = view.sensorsdata_elementId;
    properties[kSAEventPropertyElementType] = view.sensorsdata_elementType;
    properties[kSAEventPropertyElementContent] = view.sensorsdata_elementContent;
    properties[kSAEventPropertyElementPosition] = view.sensorsdata_elementPosition;
    [properties addEntriesFromDictionary:view.sensorsAnalyticsViewProperties];

    // viewPath
    NSDictionary *viewPathProperties = [[SAModuleManager sharedInstance] propertiesWithView:view];
    if (viewPathProperties) {
        [properties addEntriesFromDictionary:viewPathProperties];
    }
    return properties;
}

+ (NSDictionary *)propertiesWithScrollView:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath {
    UIView *cell = [self cellWithScrollView:scrollView andIndexPath:indexPath];
    return [self propertiesWithScrollView:scrollView cell:cell];
}

+ (NSDictionary *)propertiesWithScrollView:(UIScrollView *)scrollView cell:(UIView *)cell {
    if (!cell) {
        return nil;
    }
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    UIViewController *viewController = scrollView.sensorsdata_viewController;
    NSDictionary *dic = [self propertiesWithViewController:viewController];
    [properties addEntriesFromDictionary:dic];

    properties[kSAEventPropertyElementId] = scrollView.sensorsdata_elementId;
    properties[kSAEventPropertyElementType] = scrollView.sensorsdata_elementType;
    properties[kSAEventPropertyElementContent] = cell.sensorsdata_elementContent;
    properties[kSAEventPropertyElementPosition] = cell.sensorsdata_elementPosition;

    //View Properties
    NSDictionary *viewProperties = scrollView.sensorsAnalyticsViewProperties;
    if (viewProperties.count > 0) {
        [properties addEntriesFromDictionary:viewProperties];
    }

    // viewPath
    NSDictionary *viewPathProperties = [[SAModuleManager sharedInstance] propertiesWithView:cell];
    if (viewPathProperties) {
        [properties addEntriesFromDictionary:viewPathProperties];
    }
    return [properties copy];
}

+ (NSDictionary *)propertiesWithViewController:(UIViewController *)viewController {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[kSAEventPropertyScreenName] = viewController.sensorsdata_screenName;
    properties[kSAEventPropertyTitle] = viewController.sensorsdata_title;

    SEL getTrackProperties = NSSelectorFromString(@"getTrackProperties");
    if ([viewController respondsToSelector:getTrackProperties]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSDictionary *trackProperties = [viewController performSelector:getTrackProperties];
#pragma clang diagnostic pop
        if ([SAValidator isValidDictionary:trackProperties]) {
            [properties addEntriesFromDictionary:trackProperties];
        }
    }
    return [properties copy];
}

+ (UIView *)cellWithScrollView:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath {
    UIView *cell = nil;
    if ([scrollView isKindOfClass:UITableView.class]) {
        UITableView *tableView = (UITableView *)scrollView;
        cell = [tableView cellForRowAtIndexPath:indexPath];
        if (!cell) {
            [tableView layoutIfNeeded];
            cell = [tableView cellForRowAtIndexPath:indexPath];
        }
    } else if ([scrollView isKindOfClass:UICollectionView.class]) {
        UICollectionView *collectionView = (UICollectionView *)scrollView;
        cell = [collectionView cellForItemAtIndexPath:indexPath];
        if (!cell) {
            [collectionView layoutIfNeeded];
            cell = [collectionView cellForItemAtIndexPath:indexPath];
        }
    }
    return cell;
}

+ (NSDictionary *)propertiesWithAutoTrackDelegate:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *properties = nil;
    @try {
        if ([scrollView isKindOfClass:UITableView.class]) {
            UITableView *tableView = (UITableView *)scrollView;

            if ([tableView.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_tableView:autoTrackPropertiesAtIndexPath:)]) {
                properties = [tableView.sensorsAnalyticsDelegate sensorsAnalytics_tableView:tableView autoTrackPropertiesAtIndexPath:indexPath];
            }
        } else if ([scrollView isKindOfClass:UICollectionView.class]) {
            UICollectionView *collectionView = (UICollectionView *)scrollView;
            if ([collectionView.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_collectionView:autoTrackPropertiesAtIndexPath:)]) {
                properties = [collectionView.sensorsAnalyticsDelegate sensorsAnalytics_collectionView:collectionView autoTrackPropertiesAtIndexPath:indexPath];
            }
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
    NSAssert(!properties || [properties isKindOfClass:[NSDictionary class]], @"You must return a dictionary object ❌");
    return properties;
}

@end
