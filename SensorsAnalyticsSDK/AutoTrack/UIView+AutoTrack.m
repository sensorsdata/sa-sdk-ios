//
//  UIView+sa_autoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/6/11.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "UIView+AutoTrack.h"
#import "SAAutoTrackUtils.h"
#import "SensorsAnalyticsSDK.h"
#import <objc/runtime.h>

static void *const kSALastAppClickIntervalPropertyName = (void *)&kSALastAppClickIntervalPropertyName;

#pragma mark - UIView

@implementation UIView (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    if (self.isHidden || self.sensorsAnalyticsIgnoreView) {
        return YES;
    }
    
    BOOL isAutoTrackEnabled = [[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled];
    BOOL isAutoTrackEventTypeIgnored = [[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick];
    BOOL isViewTypeIgnored = [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[self class]];
    return !isAutoTrackEnabled || isAutoTrackEventTypeIgnored || isViewTypeIgnored;
}

- (void)setSensorsdata_timeIntervalForLastAppClick:(NSTimeInterval)sensorsdata_timeIntervalForLastAppClick {
    objc_setAssociatedObject(self, kSALastAppClickIntervalPropertyName, [NSNumber numberWithDouble:sensorsdata_timeIntervalForLastAppClick], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)sensorsdata_timeIntervalForLastAppClick {
    return [objc_getAssociatedObject(self, kSALastAppClickIntervalPropertyName) doubleValue];
}

- (NSString *)sensorsdata_elementType {

    // 采集弹框类型（UIAlertController、UIActionSheet、UIAlertView）
    if ([SAAutoTrackUtils isAlertForResponder:self]) {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
        UIWindow *window = self.window;
        if ([NSStringFromClass(window.class) isEqualToString:@"_UIAlertControllerShimPresenterWindow"]) {
            CGFloat actionHeight = self.bounds.size.height;
            if (actionHeight > 50) {
                return NSStringFromClass(UIActionSheet.class);
            } else {
                return NSStringFromClass(UIAlertView.class);
            }
        } else {
            return NSStringFromClass(UIAlertController.class);
        }
#else
        return NSStringFromClass(UIAlertController.class);
#endif
    }
    return NSStringFromClass(self.class);
}

- (NSString *)sensorsdata_elementContent {
    NSMutableString *elementContent = [NSMutableString string];

    if ([self isKindOfClass:NSClassFromString(@"RTLabel")]) {   // RTLabel:https://github.com/honcheng/RTLabel
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([self respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [self performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                [elementContent appendString:title];
            }
        }
    } else if ([self isKindOfClass:NSClassFromString(@"YYLabel")]) {    // RTLabel:https://github.com/ibireme/YYKit
        if ([self respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [self performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                [elementContent appendString:title];
            }
        }
#pragma clang diagnostic pop
    } else if ([self isKindOfClass:NSClassFromString(@"RCTView")]) { // RCTView RN 元素，https://reactnative.dev
        NSString *content = [self.accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (content.length > 0) {
            [elementContent appendString:content];
        }
    } else {
        NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            // 忽略隐藏控件
            if (subview.isHidden || subview.sensorsAnalyticsIgnoreView) {
                continue;
            }
            NSString *temp = subview.sensorsdata_elementContent;
            if (temp.length > 0) {
                [elementContentArray addObject:temp];
            }
        }
        if (elementContentArray.count > 0) {
            [elementContent appendString:[elementContentArray componentsJoinedByString:@"-"]];
        }
    }

    return elementContent.length == 0 ? nil : [elementContent copy];
}

- (NSString *)sensorsdata_elementPosition {
    UIView *superview = self.superview;
    if (superview && superview.sensorsdata_elementPosition) {
        return superview.sensorsdata_elementPosition;
    }
    return nil;
}

- (NSString *)sensorsdata_elementId {
    return self.sensorsAnalyticsViewID;
}

- (UIViewController *)sensorsdata_viewController {
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:self];

    // 获取当前 controller 作为 screen_name
    if ([viewController isKindOfClass:UINavigationController.class] || [viewController isKindOfClass:UIAlertController.class]) {
        viewController = [SAAutoTrackUtils currentViewController];
    }
    return viewController;
}

- (NSString *)sensorsdata_itemPath {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    /* 忽略路径
     UITableViewWrapperView 为 iOS11 以下 UITableView 与 cell 之间的 view
     */
    if ([NSStringFromClass(self.class) isEqualToString:@"UITableViewWrapperView"]) {
        return nil;
    }
#endif

    NSInteger index = [SAAutoTrackUtils itemIndexForResponder:self];
    NSString *className = NSStringFromClass(self.class);
    return index < 0 ? className : [NSString stringWithFormat:@"%@[%ld]", className, (long)index];
}

- (NSString *)sensorsdata_similarPath {
    // 是否支持限定元素位置功能
    BOOL isCell = [self isKindOfClass:UITableViewCell.class] || [self isKindOfClass:UICollectionViewCell.class];
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    BOOL isItem = [NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"] || [NSStringFromClass(self.class) isEqualToString:@"UISegment"];
#else
    BOOL isItem = NO;
#endif

    BOOL enableSupportSimilarPath = isCell || isItem;
    if (self.sensorsdata_elementPosition && enableSupportSimilarPath) {
        NSString *similarPath = [NSString stringWithFormat:@"%@[-]",NSStringFromClass(self.class)];
        return similarPath;
    } else {
        return self.sensorsdata_itemPath;
    }
}

- (NSString *)sensorsdata_heatMapPath {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
        /* 忽略路径
         UITableViewWrapperView 为 iOS11 以下 UITableView 与 cell 之间的 view
         */
        if ([NSStringFromClass(self.class) isEqualToString:@"UITableViewWrapperView"]) {
            return nil;
        }
#endif

    NSString *identifier = [SAAutoTrackUtils viewIdentifierForView:self];
    if (identifier) {
        return identifier;
    }
    return [SAAutoTrackUtils itemHeatMapPathForResponder:self];
}

@end

@implementation UILabel (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    return self.text ?: super.sensorsdata_elementContent;
}

@end

@implementation UIImageView (AutoTrack)

- (NSString *)sensorsdata_elementContent {
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME
    NSString *imageName = self.image.sensorsAnalyticsImageName;
    if (imageName.length > 0) {
        return [NSString stringWithFormat:@"%@", imageName];
    }
#endif
    return super.sensorsdata_elementContent;
}

#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
- (NSString *)sensorsdata_elementPosition {
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        NSInteger index = [SAAutoTrackUtils itemIndexForResponder:self];
        return index >= 0 ? [NSString stringWithFormat:@"%ld",(long)index] : [super sensorsdata_elementPosition];
    }
    return [super sensorsdata_elementPosition];
}
#endif

@end

@implementation UITextView (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    return self.text ?: super.sensorsdata_elementContent;
}

@end

@implementation UISearchBar (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    return self.text;
}

@end

@implementation UITableViewHeaderFooterView (AutoTrack)

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

#pragma mark - UIControl

@implementation UIControl (AutoTrack)

#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
- (BOOL)sensorsdata_isIgnored {
    // 忽略 UITabBarItem
    BOOL ignoredUITabBarItem = [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:UITabBarItem.class] && [NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"];

    // 忽略 UIBarButtonItem
    BOOL ignoredUIBarButtonItem = [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:UIBarButtonItem.class] && ([NSStringFromClass(self.class) isEqualToString:@"UINavigationButton"] || [NSStringFromClass(self.class) isEqualToString:@"_UIButtonBarButton"]);

    return super.sensorsdata_isIgnored || ignoredUITabBarItem || ignoredUIBarButtonItem;
}

- (NSString *)sensorsdata_elementType {
    // UIBarButtonItem
    if (([NSStringFromClass(self.class) isEqualToString:@"UINavigationButton"] || [NSStringFromClass(self.class) isEqualToString:@"_UIButtonBarButton"])) {
        return @"UIBarButtonItem";
    }

    // UITabBarItem
    if ([NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"]) {
        return @"UITabBarItem";
    }
    return NSStringFromClass(self.class);
}


- (NSString *)sensorsdata_elementPosition {
    // UITabBarItem
    if ([NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"]) {
        NSInteger index = [SAAutoTrackUtils itemIndexForResponder:self];
        return [NSString stringWithFormat:@"%ld", (long)index];
    }

    return super.sensorsdata_elementPosition;
}
#endif

@end

@implementation UIButton (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    NSString *text = self.titleLabel.text;
    if (!text) {
        text = super.sensorsdata_elementContent;
    }
    return text;
}

@end

@implementation UISwitch (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    return self.on ? @"checked" : @"unchecked";
}

@end

@implementation UIStepper (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    return [NSString stringWithFormat:@"%g", self.value];
}

@end

@implementation UISegmentedControl (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    return super.sensorsdata_isIgnored || self.selectedSegmentIndex == UISegmentedControlNoSegment;
}

- (NSString *)sensorsdata_elementContent {
    return  self.selectedSegmentIndex == UISegmentedControlNoSegment ? [super sensorsdata_elementContent] : [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

- (NSString *)sensorsdata_elementPosition {
    return self.selectedSegmentIndex == UISegmentedControlNoSegment ? [super sensorsdata_elementPosition] : [NSString stringWithFormat: @"%ld", (long)self.selectedSegmentIndex];
}

#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
- (NSString *)sensorsdata_itemPath {
    // 支持单个 UISegment 创建事件。UISegment 是 UIImageView 的私有子类，表示UISegmentedControl 单个选项的显示区域
    NSString *subPath = [NSString stringWithFormat:@"%@[%ld]", @"UISegment", (long)self.selectedSegmentIndex];
    return [NSString stringWithFormat:@"%@/%@", super.sensorsdata_itemPath, subPath];
}

- (NSString *)sensorsdata_similarPath {
    NSString *subPath = [NSString stringWithFormat:@"%@[-]", @"UISegment"];
    return [NSString stringWithFormat:@"%@/%@", super.sensorsdata_itemPath, subPath];
}

- (NSString *)sensorsdata_heatMapPath {
    NSString *subPath = [NSString stringWithFormat:@"%@[%ld]", @"UISegment", (long)self.selectedSegmentIndex];
    return [NSString stringWithFormat:@"%@/%@", super.sensorsdata_heatMapPath, subPath];
}
#endif

@end

@implementation UIPageControl (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    return [NSString stringWithFormat:@"%ld", (long)self.currentPage];
}

@end

@implementation UISlider (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    return self.tracking || super.sensorsdata_isIgnored;
}

- (NSString *)sensorsdata_elementContent {
    return [NSString stringWithFormat:@"%f", self.value];
}

@end

#pragma mark - Cell

@implementation UITableViewCell (AutoTrack)

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
        return self.sensorsdata_itemPath;
    }
}

- (NSString *)sensorsdata_heatMapPath {
    if (self.sensorsdata_IndexPath) {
        return [self sensorsdata_itemPathWithIndexPath:self.sensorsdata_IndexPath];
    }
    return [super sensorsdata_heatMapPath];
}
                
- (NSString *)sensorsdata_elementPositionWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
}

- (NSString *)sensorsdata_itemPathWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.row];
}

- (NSString *)sensorsdata_similarPathWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%@[%ld][-]", NSStringFromClass(self.class), (long)indexPath.section];
}

@end

@implementation UICollectionViewCell (AutoTrack)

- (NSIndexPath *)sensorsdata_IndexPath {
    UICollectionView *collectionView = (UICollectionView *)[self superview];
    if ([collectionView isKindOfClass:UICollectionView.class]) {
        NSIndexPath *indexPath = [collectionView indexPathForCell:self];
        return indexPath;
    }
    return nil;
}

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

- (NSString *)sensorsdata_elementPositionWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.item];
}

- (NSString *)sensorsdata_itemPathWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.item];
}

- (NSString *)sensorsdata_similarPathWithIndexPath:(NSIndexPath *)indexPath {
    if ([SAAutoTrackUtils isAlertClickForView:self]) {
        return [self sensorsdata_itemPathWithIndexPath:indexPath];
    }
    return [NSString stringWithFormat:@"%@[%ld][-]", NSStringFromClass(self.class), (long)indexPath.section];
}

@end
