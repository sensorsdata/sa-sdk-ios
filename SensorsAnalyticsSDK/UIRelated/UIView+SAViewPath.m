//
// UIView+SAViewPath.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2024/3/5.
// Copyright © 2015-2024 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+SAViewPath.h"
#import "UIView+SAElementPosition.h"
#import "UIView+SAInternalProperties.h"
#import "SAUIProperties.h"

@implementation UIView (SAViewPath)

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

- (NSString *)sensorsdata_similarPath {
    // 是否支持限定元素位置功能
    BOOL enableSupportSimilarPath = [NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"];
    if (enableSupportSimilarPath && self.sensorsdata_elementPosition) {
        return [NSString stringWithFormat:@"%@[-]",NSStringFromClass(self.class)];
    } else {
        return self.sensorsdata_itemPath;
    }
}

- (NSString *)sensorsdata_elementPath {
    // 处理特殊控件
    // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)[self superview];
        if ([segmentedControl isKindOfClass:UISegmentedControl.class]) {
            return [SAUIProperties elementPathForView:segmentedControl atViewController:segmentedControl.sensorsdata_viewController];
        }
    }
    // 支持自定义属性，可见元素均上传 elementPath
    return [SAUIProperties elementPathForView:self atViewController:self.sensorsdata_viewController];
}

@end

@implementation UISegmentedControl (SAViewPath)

- (NSString *)sensorsdata_itemPath {
    // 支持单个 UISegment 创建事件。UISegment 是 UIImageView 的私有子类，表示UISegmentedControl 单个选项的显示区域
    NSString *subPath = [NSString stringWithFormat:@"UISegment[%ld]", (long)self.selectedSegmentIndex];
    return [NSString stringWithFormat:@"%@/%@", super.sensorsdata_itemPath, subPath];
}

- (NSString *)sensorsdata_similarPath {
    return [NSString stringWithFormat:@"%@/UISegment[-]", super.sensorsdata_itemPath];
}

@end

@implementation UITableViewHeaderFooterView (SAViewPath)

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

@implementation UITableViewCell (SAViewPath)

- (NSIndexPath *)sensorsdata_IndexPath {
    UITableView *tableView = (UITableView *)[self superview];
    do {
        if ([tableView isKindOfClass:UITableView.class]) {
            NSIndexPath *indexPath = [tableView indexPathForCell:self];
            return indexPath;
        }
    } while ((tableView = (UITableView *)[tableView superview]));
    return nil;
}

- (NSString *)sensorsdata_itemPath {
    NSIndexPath *indexPath = self.sensorsdata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.row];
    }
    return [super sensorsdata_itemPath];
}

- (NSString *)sensorsdata_similarPath {
    NSIndexPath *indexPath = self.sensorsdata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][-]", NSStringFromClass(self.class), (long)indexPath.section];
    }
    return self.sensorsdata_itemPath;
}


@end

@implementation UICollectionViewCell (SAViewPath)

- (NSIndexPath *)sensorsdata_IndexPath {
    UICollectionView *collectionView = (UICollectionView *)[self superview];
    if ([collectionView isKindOfClass:UICollectionView.class]) {
        NSIndexPath *indexPath = [collectionView indexPathForCell:self];
        return indexPath;
    }
    return nil;
}

- (NSString *)sensorsdata_itemPath {
    NSIndexPath *indexPath = self.sensorsdata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.item];
    }
    return [super sensorsdata_itemPath];
}

- (NSString *)sensorsdata_similarPath {
    NSIndexPath *indexPath = self.sensorsdata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][-]", NSStringFromClass(self.class), (long)indexPath.section];
    } else {
        return super.sensorsdata_similarPath;
    }
}


@end

@implementation UIAlertController (SAViewPath)

- (NSString *)sensorsdata_similarPath {
    NSString *className = NSStringFromClass(self.class);
    NSInteger index = [SAUIProperties indexWithResponder:self];
    if (index < 0) { // -1
        return className;
    }
    return [NSString stringWithFormat:@"%@[%ld]", className, (long)index];
}

@end
