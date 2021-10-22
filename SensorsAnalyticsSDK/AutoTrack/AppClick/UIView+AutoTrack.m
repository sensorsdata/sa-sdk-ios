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
#import "SensorsAnalyticsSDK+Private.h"
#import <objc/runtime.h>
#import "SAViewElementInfoFactory.h"
#import "SAAutoTrackManager.h"

static void *const kSALastAppClickIntervalPropertyName = (void *)&kSALastAppClickIntervalPropertyName;

#pragma mark - UIView

@implementation UIView (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    if (self.isHidden || self.sensorsAnalyticsIgnoreView) {
        return YES;
    }

    return [SAAutoTrackManager.defaultManager.appClickTracker isIgnoreEventWithView:self];
}

- (void)setSensorsdata_timeIntervalForLastAppClick:(NSTimeInterval)sensorsdata_timeIntervalForLastAppClick {
    objc_setAssociatedObject(self, kSALastAppClickIntervalPropertyName, [NSNumber numberWithDouble:sensorsdata_timeIntervalForLastAppClick], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)sensorsdata_timeIntervalForLastAppClick {
    return [objc_getAssociatedObject(self, kSALastAppClickIntervalPropertyName) doubleValue];
}

- (NSString *)sensorsdata_elementType {
    SAViewElementInfo *elementInfo = [SAViewElementInfoFactory elementInfoWithView:self];
    return elementInfo.elementType;
}

- (NSString *)sensorsdata_elementContent {
    if ([self isKindOfClass:NSClassFromString(@"RTLabel")]) {   // RTLabel:https://github.com/honcheng/RTLabel
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([self respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [self performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                return title;
            }
        }
        return nil;
    }
    if ([self isKindOfClass:NSClassFromString(@"YYLabel")]) {    // RTLabel:https://github.com/ibireme/YYKit
        if ([self respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [self performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                return title;
            }
        }
        return nil;
#pragma clang diagnostic pop
    }
    if ([SAAutoTrackUtils isKindOfRNView:self]) { // RN 元素，https://reactnative.dev
        NSString *content = [self.accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (content.length > 0) {
            return content;
        }
    }

    if ([self isKindOfClass:NSClassFromString(@"WXView")]) { // WEEX 元素，http://doc.weex.io/zh/docs/components/a.html
        NSString *content = [self.accessibilityValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (content.length > 0) {
            return content;
        }
    }

    if ([[self nextResponder] isKindOfClass:UITextField.class] && ![self isKindOfClass:UIButton.class]) {
        /* 兼容输入框的元素采集
         UITextField 本身是一个容器，包括 UITextField 的元素内容，文字是直接渲染到 view 的
         层级结构如下
         UITextField
            _UITextFieldRoundedRectBackgroundViewNeue
            UIFieldEditor（UIScrollView 的子类，只有编辑状态才包含此层）
                _UITextFieldCanvasView 或 _UISearchTextFieldCanvasView (UIView 的子类)
            _UITextFieldClearButton (可能存在)
         */
        UITextField *textField = (UITextField *)[self nextResponder];
        return [textField sensorsdata_elementContent];
    }
    if ([NSStringFromClass(self.class) isEqualToString:@"_UITextFieldCanvasView"] || [NSStringFromClass(self.class) isEqualToString:@"_UISearchTextFieldCanvasView"]) {
        
        UITextField *textField = (UITextField *)[self nextResponder];
        do {
            if ([textField isKindOfClass:UITextField.class]) {
                return [textField sensorsdata_elementContent];
            }
        } while ((textField = (UITextField *)[textField nextResponder]));
        
        return nil;
    }
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
        return [elementContentArray componentsJoinedByString:@"-"];
    }
    
    return nil;
}

- (NSString *)sensorsdata_elementPosition {
    UIView *superView = self.superview;
    if (!superView) {
        return nil;
    }
    return superView.sensorsdata_elementPosition;
}

- (NSString *)sensorsdata_elementId {
    return self.sensorsAnalyticsViewID;
}

- (UIViewController *)sensorsdata_viewController {
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:self];

    // 获取当前 controller 作为 screen_name
    if (!viewController || [viewController isKindOfClass:UIAlertController.class]) {
        viewController = [SAAutoTrackUtils currentViewController];
    }
    return viewController;
}

@end

@implementation UILabel (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    return self.text ?: super.sensorsdata_elementContent;
}

@end

@implementation UIImageView (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    NSString *imageName = self.image.sensorsAnalyticsImageName;
    if (imageName.length > 0) {
        return [NSString stringWithFormat:@"%@", imageName];
    }
    return super.sensorsdata_elementContent;
}

- (NSString *)sensorsdata_elementPosition {
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        NSInteger index = [SAAutoTrackUtils itemIndexForResponder:self];
        return index > 0 ? [NSString stringWithFormat:@"%ld", (long)index] : @"0";
    }
    return [super sensorsdata_elementPosition];
}

@end

@implementation UITextField (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    if (self.text) {
        return self.text;
    } else if (self.placeholder) {
        return self.placeholder;
    }
    return super.sensorsdata_elementContent;
}

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

#pragma mark - UIControl

@implementation UIControl (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    // 忽略 UITabBarItem
    BOOL ignoredUITabBarItem = [[SensorsAnalyticsSDK sdkInstance] isViewTypeIgnored:UITabBarItem.class] && [NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"];

    // 忽略 UIBarButtonItem
    BOOL ignoredUIBarButtonItem = [[SensorsAnalyticsSDK sdkInstance] isViewTypeIgnored:UIBarButtonItem.class] && ([NSStringFromClass(self.class) isEqualToString:@"UINavigationButton"] || [NSStringFromClass(self.class) isEqualToString:@"_UIButtonBarButton"]);

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
        if (index < 0) {
            index = 0;
        }
        return [NSString stringWithFormat:@"%ld", (long)index];
    }

    return super.sensorsdata_elementPosition;
}

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


- (NSString *)sensorsdata_elementPositionWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
}

@end

@implementation UICollectionViewCell (AutoTrack)

- (NSString *)sensorsdata_elementPositionWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.item];
}

@end
