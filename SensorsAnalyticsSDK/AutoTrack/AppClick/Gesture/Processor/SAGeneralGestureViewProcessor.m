//
// SAGeneralGestureViewProcessor.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/10.
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

#import "SAGeneralGestureViewProcessor.h"
#import "UIGestureRecognizer+SAAutoTrack.h"
#import "SAAlertController.h"
#import "SAAutoTrackUtils.h"
#import "SAJSONUtil.h"

static NSArray <UIView *>* sensorsdata_searchVisualSubView(NSString *type, UIView *view) {
    NSMutableArray *subViews = [NSMutableArray array];
    for (UIView *subView in view.subviews) {
        if ([type isEqualToString:NSStringFromClass(subView.class)]) {
            [subViews addObject:subView];
        } else {
            NSArray *array = sensorsdata_searchVisualSubView(type, subView);
            if (array.count > 0) {
                [subViews addObjectsFromArray:array];
            }
        }
    }
    return  [subViews copy];
}

@interface SAGeneralGestureViewProcessor ()

@property (nonatomic, strong) UIGestureRecognizer *gesture;

@end

@implementation SAGeneralGestureViewProcessor

- (instancetype)initWithGesture:(UIGestureRecognizer *)gesture {
    if (self = [super init]) {
        self.gesture = gesture;
    }
    return self;
}

- (BOOL)isTrackable {
    if ([self isIgnoreWithView:self.gesture.view]) {
        return NO;
    }
    if ([SAGestureTargetActionModel filterValidModelsFrom:self.gesture.sensorsdata_targetActionModels].count == 0) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableView {
    return self.gesture.view;
}

#pragma mark - private method
- (BOOL)isIgnoreWithView:(UIView *)view {
    static dispatch_once_t onceToken;
    static id info = nil;
    dispatch_once(&onceToken, ^{
        NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
        NSString *jsonPath = [sensorsBundle pathForResource:@"sa_autotrack_gestureview_blacklist.json" ofType:nil];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        if (jsonData) {
            info = [SAJSONUtil JSONObjectWithData:jsonData];
        }
    });
    if (![info isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    // 公开类名使用 - isKindOfClass: 判断
    id publicClasses = info[@"public"];
    if ([publicClasses isKindOfClass:NSArray.class]) {
        for (NSString *publicClass in (NSArray *)publicClasses) {
            if ([view isKindOfClass:NSClassFromString(publicClass)]) {
                return YES;
            }
        }
    }
    // 私有类名使用字符串匹配判断
    id privateClasses = info[@"private"];
    if ([privateClasses isKindOfClass:NSArray.class]) {
        if ([(NSArray *)privateClasses containsObject:NSStringFromClass(view.class)]) {
            return YES;
        }
    }
    return NO;
}

@end

#pragma mark - 适配 iOS 10 以前的 Alert
@implementation SALegacyAlertGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    // 屏蔽 SAAlertController 的点击事件
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:self.gesture.view];
    if ([viewController isKindOfClass:UIAlertController.class] && [viewController.nextResponder isKindOfClass:SAAlertController.class]) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableView {
    NSArray <UIView *>*visualViews = sensorsdata_searchVisualSubView(@"_UIAlertControllerCollectionViewCell", self.gesture.view);
    CGPoint currentPoint = [self.gesture locationInView:self.gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:self.gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - 适配 iOS 10 及以后的 Alert
@implementation SANewAlertGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    // 屏蔽 SAAlertController 的点击事件
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:self.gesture.view];
    if ([viewController isKindOfClass:UIAlertController.class] && [viewController.nextResponder isKindOfClass:SAAlertController.class]) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableView {
    NSArray <UIView *>*visualViews = sensorsdata_searchVisualSubView(@"_UIInterfaceActionCustomViewRepresentationView", self.gesture.view);
    CGPoint currentPoint = [self.gesture locationInView:self.gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:self.gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - 适配 iOS 13 的 UIMenu
@implementation SALegacyMenuGestureViewProcessor

- (UIView *)trackableView {
    NSArray <UIView *>*visualViews = sensorsdata_searchVisualSubView(@"_UIContextMenuActionView", self.gesture.view);
    CGPoint currentPoint = [self.gesture locationInView:self.gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:self.gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - 适配 iOS 14 及以后的 UIMenu
@implementation SAMenuGestureViewProcessor

- (UIView *)trackableView {
    NSArray <UIView *>*visualViews = sensorsdata_searchVisualSubView(@"_UIContextMenuActionsListCell", self.gesture.view);
    CGPoint currentPoint = [self.gesture locationInView:self.gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:self.gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - TableViewCell.contentView 上仅存在系统手势时, 不支持可视化全埋点元素选中
@implementation SATableCellGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    for (SAGestureTargetActionModel *model in self.gesture.sensorsdata_targetActionModels) {
        if (model.isValid && ![NSStringFromSelector(model.action) isEqualToString:@"_longPressGestureRecognized:"]) {
            return YES;
        }
    }
    return NO;
}

@end

#pragma mark - CollectionViewCell.contentView 上仅存在系统手势时, 不支持可视化全埋点元素选中
@implementation SACollectionCellGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    for (SAGestureTargetActionModel *model in self.gesture.sensorsdata_targetActionModels) {
        if (model.isValid && ![NSStringFromSelector(model.action) isEqualToString:@"_handleMenuGesture:"]) {
            return YES;
        }
    }
    return NO;
}

@end
