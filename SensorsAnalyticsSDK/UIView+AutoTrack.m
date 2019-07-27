//
//  UIView+sa_autoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/6/11.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
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
#import "UIView+SAHelpers.h"

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

- (NSString *)sensorsdata_elementType {
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
#pragma clang diagnostic pop
    } else if ([self isKindOfClass:NSClassFromString(@"YYLabel")]) {    // RTLabel:https://github.com/ibireme/YYKit
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([self respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [self performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                [elementContent appendString:title];
            }
        }
#pragma clang diagnostic pop
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
    return nil;
}

- (NSString *)sensorsdata_elementId {
    return self.sensorsAnalyticsViewID;
}

- (UIViewController *)sensorsdata_viewController {
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:self];
    if ([viewController isKindOfClass:UINavigationController.class]) {
        viewController = [SAAutoTrackUtils currentViewController];
    }
    return viewController;
}

- (NSString *)sensorsdata_itemPath {
    NSString *identifier = [SAAutoTrackUtils viewIdentifierForView:self];
    if (identifier) {
        return identifier;
    }
    return [SAAutoTrackUtils itemPathForResponder:self];
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
        return [NSString stringWithFormat:@"$%@", imageName];
    }
#endif
    return super.sensorsdata_elementContent;
}

@end

@implementation UITextView (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    return self.text ?: super.sensorsdata_elementContent;
}

@end

@implementation UITabBar (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    return self.selectedItem.title;
}

- (NSString *)sensorsdata_elementPosition {
    return [NSString stringWithFormat: @"%ld", (long)[self.items indexOfObject:self.selectedItem]];
}

- (NSString *)sensorsdata_itemPath {
    NSInteger selectedIndex = [self.items indexOfObject:self.selectedItem];
    NSString *subPath = [NSString stringWithFormat:@"%@[%ld]", @"UITabBarButton", (long)selectedIndex];
    return [NSString stringWithFormat:@"%@/%@", super.sensorsdata_itemPath, subPath];
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

@end

#pragma mark - UIControl

@implementation UIButton (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    NSString *text = self.titleLabel.text;
    if (!text) {
        text = super.sensorsdata_elementContent;
    }
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME
    if (text.length == 0) {
        NSString *imageName = self.currentImage.sensorsAnalyticsImageName;
        if (imageName.length > 0) {
            return [NSString stringWithFormat:@"$%@", imageName];
        }
    }
#endif
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
    return [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

- (NSString *)sensorsdata_elementPosition {
    return [NSString stringWithFormat: @"%ld", (long)self.selectedSegmentIndex];
}

- (NSString *)sensorsdata_itemPath {
    NSString *subPath = [NSString stringWithFormat:@"%@[%ld]", @"UISegment", (long)self.selectedSegmentIndex];
    return [NSString stringWithFormat:@"%@/%@", super.sensorsdata_itemPath, subPath];
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

#pragma mark - UITabBarItem
@implementation UITabBarItem (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    BOOL isAutoTrackEnabled = [[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled];
    BOOL isAutoTrackEventTypeIgnored = [[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick];
    BOOL isViewTypeIgnored = [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[self class]];
    return !isAutoTrackEnabled || isAutoTrackEventTypeIgnored || isViewTypeIgnored;
}

- (NSString *)sensorsdata_elementId {
    return nil;
}

- (NSString *)sensorsdata_elementType {
    return NSStringFromClass(self.class);
}

- (NSString *)sensorsdata_elementContent {
    return self.title;
}

- (NSString *)sensorsdata_elementPosition {
    return nil;
}

- (UIViewController *)sensorsdata_viewController {
    return nil;
}

@end

#pragma mark - Cell

@implementation UITableViewCell (AutoTrack)

- (NSString *)sensorsdata_elementPositionWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
}

- (NSString *)sensorsdata_itemPathWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.row];
}

@end

@implementation UICollectionViewCell (AutoTrack)

- (NSString *)sensorsdata_elementPositionWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
}

- (NSString *)sensorsdata_itemPathWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.row];
}

@end
