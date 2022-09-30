//
// UIView+SAElementPosition.m
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
