//
// SAViewNodeFactory.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAViewNodeFactory.h"
#import "SAVisualizedUtils.h"
#import "SAViewNode.h"
#import "UIView+SARNView.h"
#import "SAUIProperties.h"

@implementation SAViewNodeFactory

+ (nullable SAViewNode *)viewNodeWithView:(UIView *)view {
    if ([NSStringFromClass(view.class) isEqualToString:@"UISegment"]) {
        return [[SASegmentNode alloc] initWithView:view];
    } else if ([view isKindOfClass:UISegmentedControl.class]) {
        return [[SASegmentedControlNode alloc] initWithView:view];
    } else if ([view isKindOfClass:UITableViewHeaderFooterView.class]) {
        return [[SATableViewHeaderFooterViewNode alloc] initWithView:view];
    } else if ([view isKindOfClass:UITableViewCell.class] || [view isKindOfClass:UICollectionViewCell.class]) {
        return [[SACellNode alloc] initWithView:view];
    } else if ([NSStringFromClass(view.class) isEqualToString:@"UITabBarButton"]) {
        // UITabBarItem 点击事件，支持限定元素位置
        return [[SATabBarButtonNode alloc] initWithView:view];
    } else if ([view isSensorsdataRNView]) {
        return [[SARNViewNode alloc] initWithView:view];
    } else if ([view isKindOfClass:WKWebView.class]) {
        return [[SAWKWebViewNode alloc] initWithView:view];
    } else if ([SAUIProperties isIgnoredItemPathWithView:view]) {
        /* 忽略路径
         1. UITableViewWrapperView 为 iOS11 以下 UITableView 与 cell 之间的 view
         
         2. _UITextFieldCanvasView 和 _UISearchBarFieldEditor 都是 UISearchBar 内部私有 view
         在输入状态下层级关系为：  ...UISearchBarTextField/_UISearchBarFieldEditor/_UITextFieldCanvasView
         非输入状态下层级关系为： .../UISearchBarTextField/_UITextFieldCanvasView
         并且 _UITextFieldCanvasView 是个私有 view,无法获取元素内容。_UISearchBarFieldEditor 是私有 UITextField，可以获取内容
         不论是否输入都准确标识，为方便路径统一，所以忽略 _UISearchBarFieldEditor 路径
         
         3.  UIFieldEditor 是 UITextField 内，只有编辑状态才包含的一层 view，路径忽略，方便统一（自定义属性一般圈选的为 _UITextFieldCanvasView）
         */
        return [[SAIgnorePathNode alloc] initWithView:view];
    } else {
        return [[SAViewNode alloc] initWithView:view];
    }
}

@end
