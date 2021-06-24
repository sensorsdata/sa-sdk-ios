//
//  SAAutoTrackUtils.m
//  SensorsAnalyticsSDK
//
//  Created by MC on 2019/4/22.
//  Copyright © 2019-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAutoTrackUtils.h"
#import "SAConstants+Private.h"
#import "SACommonUtility.h"
#import "SensorsAnalyticsSDK.h"
#import "UIView+AutoTrack.h"
#import "SALog.h"
#import "SAAlertController.h"
#import "SAValidator.h"
#import "SAModuleManager.h"

/// 一个元素 $AppClick 全埋点最小时间间隔，100 毫秒
static NSTimeInterval SATrackAppClickMinTimeInterval = 0.1;

@implementation SAAutoTrackUtils

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

+ (UIViewController *)currentViewController {
    __block UIViewController *currentViewController = nil;
    void (^ block)(void) = ^{
        UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
        currentViewController = [SAAutoTrackUtils findCurrentViewControllerFromRootViewController:rootViewController isRoot:YES];
    };

    [SACommonUtility performBlockOnMainThread:block];
    return currentViewController;
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

///  在间隔时间内是否采集 $AppClick 全埋点
+ (BOOL)isValidAppClickForObject:(id<SAAutoTrackViewProperty>)object {
    if (!object) {
        return NO;
    }
    
    if (![object respondsToSelector:@selector(sensorsdata_timeIntervalForLastAppClick)]) {
        return YES;
    }

    NSTimeInterval lastTime = object.sensorsdata_timeIntervalForLastAppClick;
    NSTimeInterval currentTime = [[NSProcessInfo processInfo] systemUptime];
    if (lastTime > 0 && currentTime - lastTime < SATrackAppClickMinTimeInterval) {
        return NO;
    }
    return YES;
}

// 判断是否为 RN 元素
+ (BOOL)isKindOfRNView:(UIView *)view {
    NSString *className = NSStringFromClass(view.class);
    if ([className isEqualToString:@"UISegment"]) {
        // 针对 UISegment，可能是 RCTSegmentedControl 或 RNCSegmentedControl 内嵌元素，使用父视图判断是否为 RN 元素
        view = [view superview];
    }
    NSArray <NSString *> *classNames = @[@"RCTSurfaceView", @"RCTSurfaceHostingView", @"RCTFPSGraph", @"RCTModalHostView", @"RCTView", @"RCTTextView", @"RCTRootView",  @"RCTInputAccessoryView", @"RCTInputAccessoryViewContent", @"RNSScreenContainerView", @"RNSScreen", @"RCTVideo", @"RCTSwitch", @"RCTSlider", @"RCTSegmentedControl", @"RNGestureHandlerButton", @"RNCSlider", @"RNCSegmentedControl"];
    for (NSString *className in classNames) {
        Class class = NSClassFromString(className);
        if (class && [view isKindOfClass:class]) {
            return YES;
        }
    }
    return NO;
}

@end

#pragma mark -
@implementation SAAutoTrackUtils (Property)

+ (NSInteger)itemIndexForResponder:(UIResponder *)responder {
    NSString *classString = NSStringFromClass(responder.class);
    NSInteger count = 0;
    NSInteger index = -1;
    NSArray<UIResponder *> *brothersResponder = [self brothersElementForResponder:responder];

    for (UIResponder *res in brothersResponder) {
        if ([classString isEqualToString:NSStringFromClass(res.class)]) {
            count++;
        }
        if (res == responder) {
            index = count - 1;
        }
    }
    // 单个 UIViewController（即不存在其他兄弟 viewController） 拼接路径，不需要序号
    if ([responder isKindOfClass:UIViewController.class] && ![responder isKindOfClass:UIAlertController.class] && count == 1) {
        return -2;
    }

    /* 序号说明
     -2：nextResponder 不是父视图或同类元素，比如 controller.view，涉及路径不带序号
     -1：同级只存在一个同类元素
     >=0：元素序号
     */
    // 如果 responder 是 UIViewController.view，此时 count = 0
    return count == 0 || count == 1 ? count - 2 : index;
}

/// 寻找所有兄弟元素
+ (NSArray <UIResponder *> *)brothersElementForResponder:(UIResponder *)responder {
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

+ (NSDictionary<NSString *, NSString *> *)propertiesWithViewController:(UIViewController<SAAutoTrackViewControllerProperty> *)viewController {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[kSAEventPropertyScreenName] = viewController.sensorsdata_screenName;
    properties[kSAEventPropertyTitle] = viewController.sensorsdata_title;
    
    if ([viewController conformsToProtocol:@protocol(SAAutoTracker)] &&
        [viewController respondsToSelector:@selector(getTrackProperties)]) {
        NSDictionary *trackProperties = [(UIViewController<SAAutoTracker> *)viewController getTrackProperties];
        if ([SAValidator isValidDictionary:trackProperties]) {
            [properties addEntriesFromDictionary:trackProperties];
        }
    }

    return [properties copy];
}

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackViewProperty>)object {
    return [self propertiesWithAutoTrackObject:object viewController:nil isCodeTrack:NO];
}

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackViewProperty>)object isCodeTrack:(BOOL)isCodeTrack {
    return [self propertiesWithAutoTrackObject:object viewController:nil isCodeTrack:isCodeTrack];
}

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackViewProperty>)object viewController:(nullable UIViewController<SAAutoTrackViewControllerProperty> *)viewController {
    return [self propertiesWithAutoTrackObject:object viewController:viewController isCodeTrack:NO];
}

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackViewProperty>)object viewController:(nullable UIViewController<SAAutoTrackViewControllerProperty> *)viewController isCodeTrack:(BOOL)isCodeTrack {
    if (![object respondsToSelector:@selector(sensorsdata_isIgnored)] || (!isCodeTrack && object.sensorsdata_isIgnored)) {
        return nil;
    }

    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    // ViewID
    properties[kSAEventPropertyElementId] = object.sensorsdata_elementId;

    viewController = viewController ? : object.sensorsdata_viewController;
    if (!isCodeTrack && viewController.sensorsdata_isIgnored) {
        return nil;
    }

    NSDictionary *dic = [self propertiesWithViewController:viewController];
    [properties addEntriesFromDictionary:dic];

    properties[kSAEventPropertyElementType] = object.sensorsdata_elementType;
    properties[kSAEventPropertyElementContent] = object.sensorsdata_elementContent;
    properties[kSAEventPropertyElementPosition] = object.sensorsdata_elementPosition;

    UIView *view = (UIView *)object;
    //View Properties
    if ([object isKindOfClass:UIView.class]) {
        [properties addEntriesFromDictionary:view.sensorsAnalyticsViewProperties];
    } else {
        return properties;
    }

    // viewPath
    NSDictionary *viewPathProperties = [[SAModuleManager sharedInstance] propertiesWithView:view];
    if (viewPathProperties) {
        [properties addEntriesFromDictionary:viewPathProperties];
    }

    return properties;
}

@end

#pragma mark -
@implementation SAAutoTrackUtils (IndexPath)

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIScrollView<SAAutoTrackViewProperty> *)object didSelectedAtIndexPath:(NSIndexPath *)indexPath {
    if (![object respondsToSelector:@selector(sensorsdata_isIgnored)] || object.sensorsdata_isIgnored) {
        return nil;
    }
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];

    UIView <SAAutoTrackCellProperty> *cell = (UIView <SAAutoTrackCellProperty> *)[self cellWithScrollView:object selectedAtIndexPath:indexPath];
    if (!cell) {
        return nil;
    }

    // ViewID
    properties[kSAEventPropertyElementId] = object.sensorsdata_elementId;

    UIViewController<SAAutoTrackViewControllerProperty> *viewController = object.sensorsdata_viewController;
    if (viewController.sensorsdata_isIgnored) {
        return nil;
    }

    NSDictionary *dic = [self propertiesWithViewController:viewController];
    [properties addEntriesFromDictionary:dic];

    properties[kSAEventPropertyElementType] = object.sensorsdata_elementType;
    properties[kSAEventPropertyElementContent] = cell.sensorsdata_elementContent;
    properties[kSAEventPropertyElementPosition] = [cell sensorsdata_elementPositionWithIndexPath:indexPath];

    //View Properties
    NSDictionary *viewProperties = ((UIView *)object).sensorsAnalyticsViewProperties;
    if (viewProperties.count > 0) {
        [properties addEntriesFromDictionary:viewProperties];
    }

    // viewPath
    NSDictionary *viewPathProperties = [[SAModuleManager sharedInstance] propertiesWithView:(UIView *)cell];
    if (viewPathProperties) {
        [properties addEntriesFromDictionary:viewPathProperties];
    }

    return properties;
}

+ (UIView *)cellWithScrollView:(UIScrollView *)scrollView selectedAtIndexPath:(NSIndexPath *)indexPath {
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

+ (NSDictionary *)propertiesWithAutoTrackDelegate:(UIScrollView *)scrollView didSelectedAtIndexPath:(NSIndexPath *)indexPath {
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
