//
// UIView+SAElementPath.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "SAWebElementView.h"
#import "SAAutoTrackProperty.h"
#import "SAVisualizedViewPathProperty.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIView
@interface UIView (SAVisualizedViewPath)<SAVisualizedViewPathProperty, SAVisualizedExtensionProperty>

/// 判断 ReactNative 元素是否可点击
- (BOOL)sensorsdata_clickableForRNView;

/// 判断一个 view 是否显示
- (BOOL)sensorsdata_isVisible;

@end

@interface WKWebView (SAVisualizedViewPath)<SAVisualizedViewPathProperty>

@end

@interface UIWindow (SAVisualizedViewPath)<SAVisualizedViewPathProperty>
@end

/// 其他平台的构造可视化页面元素
@interface SAVisualizedElementView (SAElementPath)<SAVisualizedViewPathProperty>
@end

/// App 内嵌 H5 页面元素信息
@interface SAWebElementView (SAElementPath)<SAVisualizedViewPathProperty>

@end

#pragma mark - UIControl
@interface UISwitch (SAVisualizedViewPath)<SAVisualizedViewPathProperty>
@end

@interface UIStepper (SAVisualizedViewPath)<SAVisualizedViewPathProperty>
@end

@interface UISlider (SAVisualizedViewPath)<SAVisualizedViewPathProperty>
@end

@interface UIPageControl (SAVisualizedViewPath)<SAVisualizedViewPathProperty>
@end

#pragma mark - TableView & Cell
@interface UITableView (SAVisualizedViewPath)<SAVisualizedViewPathProperty>
@end

@interface UICollectionView (SAVisualizedViewPath)<SAVisualizedViewPathProperty>
@end

@interface UITableViewCell (SAVisualizedViewPath)
@end

@interface UICollectionViewCell (SAVisualizedViewPath)
@end

NS_ASSUME_NONNULL_END
