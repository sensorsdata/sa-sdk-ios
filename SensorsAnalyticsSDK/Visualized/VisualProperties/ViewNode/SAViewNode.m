//
// SAViewNode.m
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAViewNode.h"
#import "SAAutoTrackUtils.h"
#import "UIView+SAVisualProperties.h"
#import "SACommonUtility.h"
#import "UIView+SAElementPath.h"
#import "UIView+AutoTrack.h"
#import "SAConstants+Private.h"
#import "SAVisualizedUtils.h"
#import "SAViewElementInfoFactory.h"
#import "SAJavaScriptBridgeManager.h"
#import "SAVisualizedManager.h"
#import "SAJSONUtil.h"
#import "SALog.h"

@interface SAViewNode()

@property (nonatomic, assign, readwrite) BOOL stopJoinPath;

/// 元素相对路径
@property (nonatomic, copy, readwrite) NSString *itemPath;

/// 元素相对模糊路径，可能包含 [-]
@property (nonatomic, copy, readwrite) NSString *similarPath;

/// 元素名称
@property (nonatomic, copy, readwrite) NSString *viewName;

/// 节点对应 view
@property (nonatomic, weak, readwrite) UIView *view;

@end

@implementation SAViewNode

- (instancetype)initWithView:(UIView *)view {
    self = [super initWithView:view];
    if (self) {
        /* 元素序号
         -2：nextResponder 不是父视图或同类元素，比如 controller.view，涉及路径不带序号
         -1：同级只存在一个同类元素，只涉及 $element_selector 不同，$element_path 照常拼接序号
         >=0：元素序号
         */
        _index = 0;
        _view = view;
        _viewName = NSStringFromClass(view.class);
        _stopJoinPath = NO;
        [self configViewNode];

        view.sensorsdata_viewNode = self;
    }
    return self;
}

#pragma mark - build
/// 初始化配置计算
- (void)configViewNode {
    // 单独处理 UIAlertController 路径信息
    UIView *view = self.view;
    UIResponder *nextResponder = [view nextResponder];
    if ([nextResponder isKindOfClass:UIAlertController.class]) {
        _viewName = [NSString stringWithFormat:@"%@/%@", NSStringFromClass(nextResponder.class), NSStringFromClass(view.class)];
    }

    [self buildNodeRelation];
}

/// 构建节点关系
- (void)buildNodeRelation {
    UIView *view = self.view;

    // 可能存在其他父节点，进行移除
    [self removeOldNodeRelation];

    /* 向下构建
     由于 didMoveToWindow 的执行顺序，是 subview -> superview，所以优先链接子节点的索引
     */
    if (!self.subNodes) {
        self.subNodes = [NSMutableArray array];
    }
    for (UIView *subView in view.subviews) {
        if (subView.sensorsdata_viewNode) {
            // 可能存在其他父节点，进行移除
            if (subView.sensorsdata_viewNode.nextNode && subView.sensorsdata_viewNode.nextNode != self) {
                [subView.sensorsdata_viewNode removeOldNodeRelation];
            }
            [subView.sensorsdata_viewNode buildNextNodeRelationWithNextNode:self];
        }
    }

    /* 向上构建
     首次遍历 keyWindow 的场景，先创建 superview 对应 Node，所以还需要尝试向上构建链接
     */
    UIResponder *nextResponder = [view nextResponder];
    UIView *nextView = [nextResponder isKindOfClass:UIView.class] ? (UIView *)nextResponder : [view superview];
    SAViewNode *nextNode = nextView.sensorsdata_viewNode;
    if (nextNode) {
        [self buildNextNodeRelationWithNextNode:nextNode];
    }

    // nextResponder 非 UIView，一般为 ViewController.view，路径拼接需要单独区分
    if (!nextResponder || ![nextResponder isKindOfClass:UIView.class]) {
        self.stopJoinPath = YES;
        self.index = -2;
    }
}

- (void)buildNextNodeRelationWithNextNode:(SAViewNode *)nextNode {
    // 链接父节点
    self.nextNode = nextNode;
    if (![nextNode.subNodes containsObject:self]) {

        NSUInteger subIndex = [nextNode.view.subviews indexOfObject:self.view];
        // 按照在 superiew.subviews 的序号，插入正确的位置
        if (subIndex != NSNotFound && nextNode.subNodes.count > subIndex) {
            [nextNode.subNodes insertObject:self atIndex:subIndex];
        } else {
            // 链接子节点
            [nextNode.subNodes addObject:self];
        }
        // 更新 index
        [self refreshIndex];
    }
}

// 移除节点的废弃链接
- (void)removeOldNodeRelation {
    SAViewNode *oldNextNode = self.nextNode;
    [oldNextNode.subNodes removeObject:self];
}

// 计算 Index 信息
- (void)refreshIndex {
    if (self.index < 0) {
        return;
    }

    NSInteger index = 0;
    for (SAViewNode *node in self.nextNode.subNodes) {
        if (node == self) {
            self.index = index;
            return;
        }

        if ([node.viewName isEqualToString:self.viewName]) {
            index++;
        }
    }
}

/// 更新所有同级同类节点 index
// 兼容 bringSubviewToFront 等视图移动
- (void)refreshBrotherNodeIndex {
    if (self.nextNode.subNodes.count == 0) {
        return;
    }

    NSInteger index = 0;
    for (SAViewNode *node in self.nextNode.subNodes) {
        if ([node.viewName isEqualToString:self.viewName]) {
            node.index = index;
            index++;

            UIResponder *nextResponder = node.view.nextResponder;
            if (!nextResponder || ![nextResponder isKindOfClass:UIView.class]) {
                node.index = -2;
            }
        }
    }
}

/// 更新页面名称
- (void)refreshScreenName {
    [SACommonUtility performBlockOnMainThread:^{
        self.screenName = [self.view sensorsdata_screenName];
    }];
}

/// 更新子节点页面名称
- (void)refreshSubNodeScreenName {
    [self refreshScreenName];
    
    for (SAViewNode *subNode in self.subNodes) {
        [subNode refreshSubNodeScreenName];
    }
}

#pragma mark - path
/* 实时获取 elementPosition
 因为 cell 刷新或重新，涉及 indexPath 重新计算，此时 cell 的子视图的 elementPosition 需要实时获取最新值
 */
- (NSString *)elementPosition {
    SAViewNode *nextNode = self.nextNode;
    if (nextNode && nextNode.elementPosition) {
        return nextNode.elementPosition;
    }
    return nil;
}

- (NSString *)itemPath {
    NSInteger index = self.index;

    // nextResponder 不是父视图或同类元素，比如 controller.view，涉及路径不带序号
    if (index < 0) {
        return self.viewName;
    }
    return [NSString stringWithFormat:@"%@[%ld]", self.viewName, (long)index];
}

- (NSString *)similarPath {
    return self.itemPath;
}

- (NSString *)elementPath {
    /* 递归  nextNode 构建 viewPath
    可以在子线程执行
    实现参考 [SAVisualizedUtils viewSimilarPathForView: atViewController: shouldSimilarPath:]
     */
    SAViewNode *currentNode = self;
    NSMutableArray *viewPathArray = [NSMutableArray array];
    BOOL isContainSimilarPath = NO;

    do {
        if (isContainSimilarPath) {     // 防止 cell 嵌套，被拼上多个 [-]
            if (currentNode.itemPath) {
                [viewPathArray addObject:currentNode.itemPath];
            }
        } else {
            NSString *currentSimilarPath = currentNode.similarPath;
            if (currentSimilarPath) {
                [viewPathArray addObject:currentSimilarPath];
                if ([currentSimilarPath rangeOfString:@"[-]"].location != NSNotFound) {
                    isContainSimilarPath = YES;
                }
            }
        }

        // 停止拼接
        if (currentNode.isStopJoinPath) {
            break;
        }
        currentNode = currentNode.nextNode;
    } while (currentNode && [currentNode.view isKindOfClass:UIView.class]);

    NSString *viewPath = [[[viewPathArray reverseObjectEnumerator] allObjects] componentsJoinedByString:@"/"];
    return viewPath;
}

/// 日志打印
- (NSString *)description {
    NSMutableString *description = [NSMutableString string];
    if (self.viewName) {
        [description appendString:self.viewName];
    }

    NSString *content = self.elementContent;
    if (content.length > 12) {
        content = [[content substringToIndex:10] stringByAppendingString:@"-$$"];
    }
    if (content) {
        [description appendFormat:@", content: %@", content];
    }
    if (self.pageIndex >= 0) {
        [description appendFormat:@", pageIndex: %ld", (long)self.pageIndex];
    }
    [description appendFormat:@", %@: %@", self.screenName, self.elementPath];
    if (self.elementPosition) {
        [description appendFormat:@", elementPosition: %@", self.elementPosition];
    }
    return [description copy];
}

@end

@implementation SASegmentNode

- (instancetype)initWithView:(UIView *)view {
    self = [super initWithView:view];
    if (self) {
        [self refreshIndex];
    }
    return self;
}

- (void)refreshIndex {
    UIView *view = self.view;
    if (![view.nextResponder isKindOfClass:UISegmentedControl.class]) {
        return;
    }

    NSString *classString = NSStringFromClass(view.class);
    // UISegmentedControl 点击之后，subviews 顺序会变化，需要根据坐标排序才能匹配正确
    UISegmentedControl *segmentedControl = (UISegmentedControl *)view.nextResponder;
    NSArray <UIView *> *subViews = segmentedControl.subviews;
    NSArray *subResponder = [subViews sortedArrayUsingComparator:^NSComparisonResult (UIView *obj1, UIView *obj2) {
        if (obj1.frame.origin.x > obj2.frame.origin.x) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];

    NSInteger count = 0;
    for (UIResponder *res in subResponder) {
        if ([classString isEqualToString:NSStringFromClass(res.class)]) {
            count++;
        }
        if (res == view) {
            self.index = count - 1;
        }
    }
}

- (NSString *)elementPosition {
    [SACommonUtility performBlockOnMainThread:^{
        [self refreshIndex];
    }];
    
    return [NSString stringWithFormat:@"%ld", (long)self.index];
}

// UISegmentedControl 已经拼接了 UISegment，此处忽略路径
- (NSString *)itemPath {
    return nil;
}
- (NSString *)similarPath {
    return nil;
}

- (NSString *)elementPath {
    SAViewNode *segmentedControlNode = self.nextNode;

    // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
    if (segmentedControlNode && [segmentedControlNode.view isKindOfClass:UISegmentedControl.class]) {
        return segmentedControlNode.elementPath;
    }
    return [super elementPath];
}

@end

@interface SASegmentedControlNode()
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@end

@implementation SASegmentedControlNode

- (instancetype)initWithView:(UIView *)view {
    self = [super initWithView:view];
    if (self) {
        _segmentedControl = (UISegmentedControl *)view;
    }
    return self;
}

- (NSString *)elementPosition {
    __block NSString *elementPosition = [super elementPosition];
    [SACommonUtility performBlockOnMainThread:^{
        if (self.segmentedControl.selectedSegmentIndex != UISegmentedControlNoSegment) {
            elementPosition = [NSString stringWithFormat: @"%ld", (long)self.segmentedControl.selectedSegmentIndex];
        }
    }];
    return elementPosition;
}

- (NSString *)itemPath {
    // 支持单个 UISegment 创建事件。UISegment 是 UIImageView 的私有子类，表示UISegmentedControl 单个选项的显示区域
    __block NSString *subPath = nil;
    [SACommonUtility performBlockOnMainThread:^{
        subPath = [NSString stringWithFormat:@"%@[%ld]", @"UISegment", (long)self.segmentedControl.selectedSegmentIndex];
    }];
    return [NSString stringWithFormat:@"%@/%@", super.itemPath, subPath];
}

- (NSString *)similarPath {
    NSString *subPath = [NSString stringWithFormat:@"%@[-]", @"UISegment"];
    return [NSString stringWithFormat:@"%@/%@", super.itemPath, subPath];
}

@end

@implementation SATabBarButtonNode

- (NSString *)elementPosition {
    return [NSString stringWithFormat:@"%ld", (long)self.index];
}

- (NSString *)similarPath {
    return [NSString stringWithFormat:@"%@[-]", self.viewName];
}

@end


@implementation SATableViewHeaderFooterViewNode

- (instancetype)initWithView:(UIView *)view {
    self = [super initWithView:view];
    if (self) {
        [self refreshIndex];
    }
    return self;
}

// 计算 index 并解析 viewName
- (void)refreshIndex {
    UITableView *tableView = (UITableView *)self.view.nextResponder;
    while (![tableView isKindOfClass:UITableView.class]) {
        tableView = (UITableView *)tableView.nextResponder;
        if (!tableView) {
            return;
        }
    }

    for (NSInteger i = 0; i < tableView.numberOfSections; i++) {
        if (self.view == [tableView headerViewForSection:i]) {
            self.viewName = @"[SectionHeader]";
            self.index = i;
            return;
        }
        if (self.view == [tableView footerViewForSection:i]) {
            self.viewName = @"[SectionFooter]";
            self.index = i;
            return;
        }
    }
}

@end

@interface SACellNode()
@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@implementation SACellNode

- (instancetype)initWithView:(UIView *)view {
    self = [super initWithView:view];
    if (self) {
        [self refreshIndex];
    }
    return self;
}

// 计算 indexPath
- (void)refreshIndex {
    // UITableViewCell
    if ([self.view isKindOfClass:UITableViewCell.class]) {
        UITableViewCell *cell = (UITableViewCell *)self.view;
        UITableView *tableView = (UITableView *)self.view.nextResponder;
        do {
            if ([tableView isKindOfClass:UITableView.class]) {
                self.indexPath = [tableView indexPathForCell:cell];
                return;
            }
        } while ((tableView = (UITableView *)[tableView nextResponder]));
    }

    // UICollectionViewCell
    if ([self.view isKindOfClass:UICollectionViewCell.class]) {
        UICollectionViewCell *cell = (UICollectionViewCell *)self.view;
        UICollectionView *collectionView = (UICollectionView *)[cell nextResponder];
        if ([collectionView isKindOfClass:UICollectionView.class]) {
            self.indexPath = [collectionView indexPathForCell:cell];
            return;
        }
    }
}

-(NSIndexPath *)indexPath {
    if (!_indexPath) {
        [SACommonUtility performBlockOnMainThread:^{
            if ([SAVisualizedUtils isVisibleForView:self.view]) {
                [self refreshIndex];
            }
        }];
    }
    return _indexPath;
}

- (NSString *)itemPath {
    if (self.indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][%ld]", self.viewName, (long)self.indexPath.section, (long)self.indexPath.row];
    }
    return super.itemPath;
}

- (NSString *)similarPath {
    if (self.indexPath) {
        // 弹框或 menu 等，不支持限定位置
        SAViewElementInfo *elementInfo = [SAViewElementInfoFactory elementInfoWithView:self.view];
        if (!elementInfo.isSupportElementPosition) {
            return self.itemPath;
        }
        return [NSString stringWithFormat:@"%@[%ld][-]", self.viewName, (long)self.indexPath.section];
    }
    return super.similarPath;
}

- (NSString *)elementPosition {
    // 弹框或 menu 等，不支持限定位置
    SAViewElementInfo *elementInfo = [SAViewElementInfoFactory elementInfoWithView:self.view];
    if (!elementInfo.isSupportElementPosition) {
        return nil;
    }

    if (self.indexPath) {
        return [NSString stringWithFormat: @"%ld:%ld", (long)self.indexPath.section, (long)self.indexPath.row];
    }
    return [super elementPosition];
}
@end

@implementation SARNViewNode
- (instancetype)initWithView:(UIView *)view {
    [SARNViewNode bindScreenNameWithClickableView:view];
    self = [super initWithView:view];
    return self;
}

/// 触发 RN 插件可点击元素的页面信息绑定，使得和上传页面信息逻辑一致
+ (void)bindScreenNameWithClickableView:(UIView *)rnView {
    [rnView sensorsdata_clickableForRNView];
}

@end


@implementation SAWKWebViewNode

- (void)callJSSendVisualConfig:(NSDictionary *)configResponse {
    if (configResponse.count == 0) {
        return;
    }
    if (![self.view isKindOfClass:WKWebView.class]) {
        return;
    }

    WKWebView *webView = (WKWebView *)self.view;
    // 判断打通才注入配置
    if (![SAVisualizedUtils isSupportCallJSWithWebView:webView]) {
        return;
    }
    // 调用 JS 函数，发送配置信息
    NSString *javaScriptSource = [SAJavaScriptBridgeBuilder buildCallJSMethodStringWithType:SAJavaScriptCallJSTypeUpdateVisualConfig jsonObject:configResponse];
    if (!javaScriptSource) {
        return;
    }
    [webView evaluateJavaScript:javaScriptSource completionHandler:^(id _Nullable resuts, NSError * _Nullable error) {
        if (error) {
            SALogDebug(@"%@ updateH5VisualConfig error: %@", kSAJSBridgeCallMethod, error);
        } else {
            SALogDebug(@"%@ updateH5VisualConfig finish", kSAJSBridgeCallMethod);
        }
    }];
}

@end


@implementation SAIgnorePathNode

- (NSString *)itemPath {
    return nil;
}

- (NSString *)similarPath {
    return nil;
}

@end
