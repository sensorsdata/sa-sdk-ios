//
// UIView+SAElementContent.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+SAElementContent.h"
#import "UIView+SensorsAnalytics.h"
#import "UIView+SARNView.h"

@implementation UIView (SAElementContent)

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
    if ([self isSensorsdataRNView]) { // RN 元素，https://reactnative.dev
        NSString *content = [self.accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (content.length > 0) {
            return content;
        }
    }

    if ([self isKindOfClass:NSClassFromString(@"WXView")] || [self isKindOfClass:NSClassFromString(@"WXImageView")] || [self isKindOfClass: NSClassFromString(@"WXText")]) { // WEEX 元素，http://doc.weex.io/zh/docs/components/a.html
        NSString *content = [self.accessibilityValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (content.length > 0) {
            return content;
        }
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

@end

@implementation UILabel (SAElementContent)

- (NSString *)sensorsdata_elementContent {
    return self.text ?: super.sensorsdata_elementContent;
}

@end

@implementation UIImageView (SAElementContent)

- (NSString *)sensorsdata_elementContent {
    NSString *imageName = self.image.sensorsAnalyticsImageName;
    if (imageName.length > 0) {
        return [NSString stringWithFormat:@"%@", imageName];
    }
    return super.sensorsdata_elementContent;
}

@end

@implementation UISearchBar (SAElementContent)

- (NSString *)sensorsdata_elementContent {
    return self.text;
}

@end

@implementation UIButton (SAElementContent)

- (NSString *)sensorsdata_elementContent {
    NSString *text = self.titleLabel.text;
    if (!text) {
        text = super.sensorsdata_elementContent;
    }
    return text;

}

@end

@implementation UISwitch (SAElementContent)

- (NSString *)sensorsdata_elementContent {
    return self.on ? @"checked" : @"unchecked";
}

@end

@implementation UIStepper (SAElementContent)

- (NSString *)sensorsdata_elementContent {
    return [NSString stringWithFormat:@"%g", self.value];
}

@end

@implementation UISegmentedControl (SAElementContent)

- (NSString *)sensorsdata_elementContent {
    return  self.selectedSegmentIndex == UISegmentedControlNoSegment ? [super sensorsdata_elementContent] : [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

@end

@implementation UIPageControl (SAElementContent)

- (NSString *)sensorsdata_elementContent {
    return [NSString stringWithFormat:@"%ld", (long)self.currentPage];
}

@end

@implementation UISlider (SAElementContent)

- (NSString *)sensorsdata_elementContent {
    return [NSString stringWithFormat:@"%f", self.value];
}

@end
