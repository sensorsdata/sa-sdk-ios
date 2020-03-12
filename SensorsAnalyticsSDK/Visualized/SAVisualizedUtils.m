//
// SAVisualizedUtils.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/3.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAVisualizedUtils.h"

@implementation SAVisualizedUtils


+ (BOOL)isCoveredForView:(UIView *)view {
    BOOL covered = NO;
    
    // 最多查找 3 层
    NSArray <UIView *> *allOtherViews = [self findAllPossibleCoverViews:view hierarchyCount:3];

    // 遍历判断是否存在覆盖
    CGRect rect = [view convertRect:view.bounds toView:nil];
    for (UIView *otherView in allOtherViews) {
        CGRect otherRect = [otherView convertRect:otherView.bounds toView:nil];
        if (CGRectContainsRect(otherRect, rect)) {
            return YES;
        }
    }
    return covered;
}


// 根据层数，查询一个 view 所有可能覆盖的 view
+ (NSArray *)findAllPossibleCoverViews:(UIView *)view hierarchyCount:(NSInteger)count {
    __block NSMutableArray <UIView *> *allOtherViews = [NSMutableArray array];
    NSInteger index = count;
    UIView *currentView = view;
    while (index > 0 && currentView) {
        NSArray *allBrotherViews = [self findPossibleCoverAllBrotherViews:currentView];
          if (allBrotherViews.count > 0) {
              [allOtherViews addObjectsFromArray:allBrotherViews];
          }
        currentView = currentView.superview;
        index--;
    }
    return [allOtherViews copy];
}


// 寻找一个 view 同级的后添加的 view
+ (NSArray *)findPossibleCoverAllBrotherViews:(UIView *)view {
    __block NSMutableArray <UIView *> *otherViews = [NSMutableArray array];
    UIView *superView = view.superview;
    if (superView) {
        // 逆序遍历
        [superView.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if (obj == view) {
                *stop = YES;
            } else if (obj.alpha > 0 && !obj.hidden && obj.userInteractionEnabled) { // userInteractionEnabled 为 YES 才有可能遮挡响应事件
                [otherViews addObject:obj];
            }
        }];
    }
    return otherViews;
}

@end
