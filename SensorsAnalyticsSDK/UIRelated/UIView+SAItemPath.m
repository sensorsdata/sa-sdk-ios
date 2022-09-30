//
// UIView+SAItemPath.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/29.
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

#import "UIView+SAItemPath.h"
#import "SAUIProperties.h"
#import "UITableViewCell+SAIndexPath.h"

@implementation UIView (SAItemPath)

- (NSString *)sensorsdata_itemPath {
    /* 忽略路径
     UITableViewWrapperView 为 iOS11 以下 UITableView 与 cell 之间的 view
     _UITextFieldCanvasView 和 _UISearchBarFieldEditor 都是 UISearchBar 内部私有 view
     在输入状态下  ...UISearchBarTextField/_UISearchBarFieldEditor/_UITextFieldCanvasView/...
     非输入状态下 .../UISearchBarTextField/_UITextFieldCanvasView
     并且 _UITextFieldCanvasView 是个私有 view,无法获取元素内容(目前通过 nextResponder 获取 textField 采集内容)。方便路径统一，所以忽略 _UISearchBarFieldEditor 路径
     */
    if ([SAUIProperties isIgnoredItemPathWithView:self]) {
        return nil;
    }

    NSString *className = NSStringFromClass(self.class);
    NSInteger index = [SAUIProperties indexWithResponder:self];
    if (index < 0) { // -1
        return className;
    }
    return [NSString stringWithFormat:@"%@[%ld]", className, (long)index];
}

@end

@implementation UISegmentedControl (SAItemPath)

- (NSString *)sensorsdata_itemPath {
    // 支持单个 UISegment 创建事件。UISegment 是 UIImageView 的私有子类，表示UISegmentedControl 单个选项的显示区域
    NSString *subPath = [NSString stringWithFormat:@"UISegment[%ld]", (long)self.selectedSegmentIndex];
    return [NSString stringWithFormat:@"%@/%@", super.sensorsdata_itemPath, subPath];
}

@end

@implementation UITableViewHeaderFooterView (SAItemPath)

- (NSString *)sensorsdata_itemPath {
    UITableView *tableView = (UITableView *)self.superview;

    while (![tableView isKindOfClass:UITableView.class]) {
        tableView = (UITableView *)tableView.superview;
        if (!tableView) {
            return super.sensorsdata_itemPath;
        }
    }
    for (NSInteger i = 0; i < tableView.numberOfSections; i++) {
        if (self == [tableView headerViewForSection:i]) {
            return [NSString stringWithFormat:@"[SectionHeader][%ld]", (long)i];
        }
        if (self == [tableView footerViewForSection:i]) {
            return [NSString stringWithFormat:@"[SectionFooter][%ld]", (long)i];
        }
    }
    return super.sensorsdata_itemPath;
}

@end

@implementation UITableViewCell (SAItemPath)

- (NSString *)sensorsdata_itemPath {
    NSIndexPath *indexPath = self.sensorsdata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.row];
    }
    return [super sensorsdata_itemPath];
}

@end

@implementation UICollectionViewCell (SAItemPath)

- (NSString *)sensorsdata_itemPath {
    NSIndexPath *indexPath = self.sensorsdata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.item];
    }
    return [super sensorsdata_itemPath];
}

@end

