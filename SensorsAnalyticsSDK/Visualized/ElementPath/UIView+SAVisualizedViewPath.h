//
// UIView+SAElementPath.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/6.
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

@interface UIScrollView (SAVisualizedViewPath)<SAVisualizedExtensionProperty>
@end

@interface WKWebView (SAVisualizedViewPath)<SAVisualizedViewPathProperty>

@end

@interface UIWindow (SAVisualizedViewPath)<SAVisualizedViewPathProperty>
@end

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
