//
// UIView+SASimilarPath.m
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

#import "UIView+SASimilarPath.h"
#import "UIView+SAElementPosition.h"
#import "UIView+SAItemPath.h"
#import "UITableViewCell+SAIndexPath.h"

@implementation UIView (SASimilarPath)

- (NSString *)sensorsdata_similarPath {
    // 是否支持限定元素位置功能
    BOOL enableSupportSimilarPath = [NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"];
    if (enableSupportSimilarPath && self.sensorsdata_elementPosition) {
        return [NSString stringWithFormat:@"%@[-]",NSStringFromClass(self.class)];
    } else {
        return self.sensorsdata_itemPath;
    }
}

@end

@implementation UISegmentedControl (SASimilarPath)

- (NSString *)sensorsdata_similarPath {
    return [NSString stringWithFormat:@"%@/UISegment[-]", super.sensorsdata_itemPath];
}

@end

@implementation UITableViewCell (SASimilarPath)

- (NSString *)sensorsdata_similarPath {
    NSIndexPath *indexPath = self.sensorsdata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][-]", NSStringFromClass(self.class), (long)indexPath.section];
    }
    return self.sensorsdata_itemPath;
}

@end

@implementation UICollectionViewCell (SASimilarPath)

- (NSString *)sensorsdata_similarPath {
    NSIndexPath *indexPath = self.sensorsdata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][-]", NSStringFromClass(self.class), (long)indexPath.section];
    } else {
        return super.sensorsdata_similarPath;
    }
}

@end
