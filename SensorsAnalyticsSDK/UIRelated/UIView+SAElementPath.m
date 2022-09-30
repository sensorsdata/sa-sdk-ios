//
// UIView+SAElementPath.m
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

#import "UIView+SAElementPath.h"
#import "SAUIProperties.h"
#import "SAUIInternalProperties.h"
#import "UIView+SAInternalProperties.h"

@implementation UIView (SAElementPath)

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
