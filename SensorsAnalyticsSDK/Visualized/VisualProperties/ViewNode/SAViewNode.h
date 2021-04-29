//
// SAViewNode.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/6.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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
#import "SAVisualPropertiesConfig.h"

NS_ASSUME_NONNULL_BEGIN

/// 构造页面元素，用于绑定属性
@interface SAViewNode : SAViewIdentifier

#pragma mark path
/// 是否停止拼接相对路径，如果 nextResponder 为 UIViewController 则不再继续拼接
@property (nonatomic, assign, readonly, getter=isStopJoinPath) BOOL stopJoinPath;

/// 元素相对路径，依赖于 index 构造
@property (nonatomic, copy, readonly) NSString *itemPath;

/// 元素相对模糊路径，可能包含 [-]，依赖于 index 构造
@property (nonatomic, copy, readonly) NSString *similarPath;

/// 元素名称
@property (nonatomic, copy, readonly) NSString *viewName;

/// 同级同类元素序号
/* -2：nextResponder 不是父视图或同类元素，比如 controller.view，涉及路径不带序号
 其他：elementPath 包含序号
 */
@property (nonatomic, assign) NSInteger index;

#pragma mark view
/// 节点对应 view
@property (nonatomic, weak, readonly) UIView *view;

/// 子节点
@property (nonatomic, strong) NSMutableArray<SAViewNode *> *subNodes;

/// 父视图对应节点
@property (nonatomic, weak) SAViewNode *nextNode;

- (instancetype)initWithView:(UIView *)view;

/// 视图更新，刷新 index
- (void)refreshIndex;

/// 更新所有同级同类节点 index
- (void)refreshBrotherNodeIndex;

/// 构建节点链接关系
- (void)buildNodeRelation;

@end

/// 处理 UISegment 逻辑
@interface SASegmentNode : SAViewNode
@end

/// 处理 UISegmentedControl
@interface SASegmentedControlNode : SAViewNode
@end

/// UITabBarItem
@interface SATabBarButtonNode : SAViewNode

@end

// 处理 UITableViewHeaderFooterView
@interface SATableViewHeaderFooterViewNode : SAViewNode
@end

/// 处理 UITableViewCell & UICollectionViewCell
@interface SACellNode : SAViewNode
@end

/// 需要忽略相对路径
@interface SAIgnorePathNode : SAViewNode

@end

NS_ASSUME_NONNULL_END
