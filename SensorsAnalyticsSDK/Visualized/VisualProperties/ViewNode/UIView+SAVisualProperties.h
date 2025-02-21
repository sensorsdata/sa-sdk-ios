//
// UIView+SAVisualPropertiey.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SAViewNode.h"

@interface UIView (SAVisualProperties)

- (void)sensorsdata_visualize_didMoveToSuperview;

- (void)sensorsdata_visualize_didMoveToWindow;

- (void)sensorsdata_visualize_didAddSubview:(UIView *)subview;

- (void)sensorsdata_visualize_bringSubviewToFront:(UIView *)view;

- (void)sensorsdata_visualize_sendSubviewToBack:(UIView *)view;

/// 视图对应的节点
@property (nonatomic, strong) SAViewNode *sensorsdata_viewNode;

@end

@interface UITableViewCell(SAVisualProperties)

- (void)sensorsdata_visualize_prepareForReuse;

@end

@interface UICollectionViewCell(SAVisualProperties)

- (void)sensorsdata_visualize_prepareForReuse;

@end

@interface UITableViewHeaderFooterView(SAVisualProperties)

- (void)sensorsdata_visualize_prepareForReuse;

@end

@interface UIWindow (SAVisualProperties)

- (void)sensorsdata_visualize_becomeKeyWindow;

@end


@interface UITabBar (SAVisualProperties)
- (void)sensorsdata_visualize_setSelectedItem:(UITabBarItem *)selectedItem;
@end


#pragma mark - 属性内容
@interface UIView (PropertiesContent)

@property (nonatomic, copy, readonly) NSString *sensorsdata_propertyContent;

@end
