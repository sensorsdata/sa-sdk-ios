//
// SAViewNodeTree.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/14.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAViewNodeTree.h"
#import "UIView+SAVisualProperties.h"
#import "UIView+SAElementPath.h"
#import "SAVisualizedUtils.h"
#import "SAViewNodeFactory.h"
#import "SACommonUtility.h"
#import "SASwizzle.h"
#import "SALog.h"

@interface SAViewNodeTree()

/// 当前根节点
@property (nonatomic, strong) SAViewNode *rootNode;

@end

@implementation SAViewNodeTree

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    // 主线程异步开始遍历，防止视图未加载完成，存在元素遗漏
    dispatch_async(dispatch_get_main_queue(), ^{
        // 遍历 keyWindow，初始化构造节点树
        UIWindow *keyWindow = [SAVisualizedUtils currentValidKeyWindow];
        // 设置根节点
        self.rootNode = [SAViewNodeFactory viewNodeWithView:keyWindow];
        // 遍历视图
        [self queryAllSubviewsWithView:keyWindow isRootView:YES];
    });

    // hook UIView 用于遍历页面元素
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        /* 备注
         测试发现：xib 自定义 tableViewCell 嵌套代码添加 UICollectionView， UICollectionView 未执行 didMoveToWindow
         didMoveToSuperview 更准确，也符合业务逻辑（index 是根据 superview.subviews 序号计算）
         */
        NSError *error = nil;
        [UIView sa_swizzleMethod:@selector(didMoveToSuperview) withMethod:@selector(sensorsdata_visualize_didMoveToSuperview) error:&error];
        if (error) {
            SALogError(@"Failed to swizzle on UIView. Error details: %@", error);
        }
        
        // 测试发现部分场景下，UINavigationTransitionView 未执行 didMoveToSuperview，但是执行了 didMoveToWindow
        [UIView sa_swizzleMethod:@selector(didMoveToWindow) withMethod:@selector(sensorsdata_visualize_didMoveToWindow) error:NULL];

        // 测试发现 UIAlertController.view 即 _UIAlertControllerView 显示，未执行 didMoveToWindow 和 didMoveToSuperview，但是其父视图调用了 didAddSubview
        [UIView sa_swizzleMethod:@selector(didAddSubview:) withMethod:@selector(sensorsdata_visualize_didAddSubview:) error:NULL];

        // bringSubviewToFront 和 sendSubviewToBack，不执行 didMoveTo 相关方法，但是会修改 index，从而改变路径
        [UIView sa_swizzleMethod:@selector(bringSubviewToFront:) withMethod:@selector(sensorsdata_visualize_bringSubviewToFront:) error:NULL];
        
        [UIView sa_swizzleMethod:@selector(sendSubviewToBack:) withMethod:@selector(sensorsdata_visualize_sendSubviewToBack:) error:NULL];
        
        // cell 被重用，需要重新计算 indexPath
        [UITableViewCell sa_swizzleMethod:@selector(prepareForReuse) withMethod:@selector(sensorsdata_visualize_prepareForReuse) error:NULL];
        
        [UICollectionViewCell sa_swizzleMethod:@selector(prepareForReuse) withMethod:@selector(sensorsdata_visualize_prepareForReuse) error:NULL];
        
        // HeaderFooterView 被重用，重新计算 index
        [UITableViewHeaderFooterView sa_swizzleMethod:@selector(prepareForReuse) withMethod:@selector(sensorsdata_visualize_prepareForReuse) error:NULL];
    });
}

/// 初始遍历页面，构造节点树
- (void)queryAllSubviewsWithView:(UIView *)view isRootView:(BOOL)isRootView {
    if (!isRootView) {
        [self addViewNodeWithView:view];
    }

    for (UIView *subView in view.subviews) {
        [self queryAllSubviewsWithView:subView isRootView:NO];
    }
}

/// 视图添加或移除
- (void)didMoveToSuperviewWithView:(UIView *)view {

    // 异步执行，防止 cell 等未加载或部分元素无法获取页面名称
    dispatch_async(dispatch_get_main_queue(), ^{
        // 视图显示
        if (view.superview) {
            [self addViewNodeWithView:view];
        } else {
            // 移除节点
            [self removeViewNodeWithView:view];
        }
    });
}

- (void)didMoveToWindowWithView:(UIView *)view {
    // 异步执行，防止 cell 等未加载或部分元素无法获取页面名称
    dispatch_async(dispatch_get_main_queue(), ^{
        // 视图显示
        if (view.window) {
            if (view.superview) {
                [self addViewNodeWithView:view];
            }
        } else {
            // 移除节点
            [self removeViewNodeWithView:view];
        }
    });
}

- (void)didAddSubview:(UIView *)subview {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (subview.superview) {
            [self addViewNodeWithView:subview];
        }
    });
}

// view 消失，移除节点
- (void)removeViewNodeWithView:(UIView *)view {
    if (view.superview || !view.sensorsdata_viewNode) {
        return;
    }

    [self updateBrotherViewNodeWithView:view isAddViewNode:NO];

    // 根据当前 view，删除节点
    view.sensorsdata_viewNode = nil;;
}

/// 显示 view，构建 node 信息
- (void)addViewNodeWithView:(UIView *)view {
    // 节点已被构建，更新链接
    if (view.sensorsdata_viewNode) {
        SAViewNode *viewNode = view.sensorsdata_viewNode;
        // 过滤重复构建
        if (view.superview == viewNode.nextNode.view) {
            return;
        }
        [viewNode buildNodeRelation];
        return;
    }

    // 部分 view 当做整体处理，不必构建子视图
    if ([self isIgnoreBuildNodeWithView:view]) {
        return;
    }

    // 构造相关节点
    UIResponder *nextResponder = view.nextResponder;
    if (!nextResponder) {
        return;
    }

    SAViewNode *node = [SAViewNodeFactory viewNodeWithView:view];
    UIView *nextView = [nextResponder isKindOfClass:UIView.class] ? (UIView *)nextResponder : [view superview];
    if (!nextView) {
        return;
    }
    // 同级同类元素个数
    NSInteger brotherViewCount = 0;
    for (SAViewNode *subNode in nextView.sensorsdata_viewNode.subNodes) {
        if ([subNode.viewName isEqualToString:node.viewName]) {
            brotherViewCount++;
        }
    }

    // view 被插入到父视图，而不是直接 addSubView，后面同级同类元素，需要更新信息
    if (node.index < brotherViewCount - 1) {
        [self updateBrotherViewNodeWithView:view isAddViewNode:YES];
    }
}

- (BOOL)isIgnoreBuildNodeWithView:(UIView *)view {
    UIView *superView = view.superview;
    UIView *nextView = [view.nextResponder isKindOfClass:UIView.class] ? (UIView *)view.nextResponder : nil;

    if ([SAVisualizedUtils isIgnoreSubviewsWithView:superView] || [SAVisualizedUtils isIgnoreSubviewsWithView:nextView]) {
        return YES;
    }
    return NO;
}

/// 更新当前 view 兄弟元素索引
- (void)updateBrotherViewNodeWithView:(UIView *)view isAddViewNode:(BOOL)isAdd {
    SAViewNode *currentNode = view.sensorsdata_viewNode;
   
    // 移除节点，先从父节点的子节点数组中移除
    if (!isAdd) {
        [currentNode.nextNode.subNodes removeObject:currentNode];
    }
    // 更新兄弟节点 index
    [currentNode refreshBrotherNodeIndex];
}

#pragma mark queryView
- (UIView *)viewWithPropertyConfig:(SAVisualPropertiesPropertyConfig *)config {
    return [self viewWithPropertyConfig:config viewNode:self.rootNode];
}

- (UIView *)viewWithPropertyConfig:(SAVisualPropertiesPropertyConfig *)config viewNode:(SAViewNode *)node {
    if ([config isMatchVisualPropertiesWithViewIdentify:node]) {
        return node.view;
    }
    __block UIView *resultView = nil;
    [node.subNodes enumerateObjectsUsingBlock:^(SAViewNode *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        UIView *view = [self viewWithPropertyConfig:config viewNode:obj];
        if (view) {
            resultView = view;
            *stop = YES;
        }
    }];
    return resultView;
}

@end
