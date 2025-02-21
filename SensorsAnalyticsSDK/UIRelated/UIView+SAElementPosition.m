//
// UIView+SAElementPosition.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+SAElementPosition.h"
#import "SAUIProperties.h"
#import "UITableViewCell+SAIndexPath.h"

@implementation UIView (SAElementPosition)

- (NSString *)sensorsdata_elementPosition {
    UIView *superView = self.superview;
    if (!superView) {
        return nil;
    }
    return superView.sensorsdata_elementPosition;
}

@end

@implementation UIImageView (SAElementPosition)

- (NSString *)sensorsdata_elementPosition {
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        NSInteger index = [SAUIProperties indexWithResponder:self];
        return index > 0 ? [NSString stringWithFormat:@"%ld", (long)index] : @"0";
    }
    return [super sensorsdata_elementPosition];
}

@end

@implementation UIControl (SAElementPosition)

- (NSString *)sensorsdata_elementPosition {
    // UITabBarItem
    if ([NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"]) {
        NSInteger index = [SAUIProperties indexWithResponder:self];
        if (index < 0) {
            index = 0;
        }
        return [NSString stringWithFormat:@"%ld", (long)index];
    }
    return super.sensorsdata_elementPosition;
}

@end

@implementation UISegmentedControl (SAElementPosition)

- (NSString *)sensorsdata_elementPosition {
    return self.selectedSegmentIndex == UISegmentedControlNoSegment ? [super sensorsdata_elementPosition] : [NSString stringWithFormat: @"%ld", (long)self.selectedSegmentIndex];
}

@end

@implementation UITableViewCell (SAElementPosition)

- (NSString *)sensorsdata_elementPosition {
    NSIndexPath *indexPath = self.sensorsdata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
    }
    return nil;
}

@end

@implementation UICollectionViewCell (SAElementPosition)

- (NSString *)sensorsdata_elementPosition {
    NSIndexPath *indexPath = self.sensorsdata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%ld:%ld", (long)indexPath.section, (long)indexPath.item];
    }
    return nil;
}

@end
