//
//  UIGestureRecognizer+SAAutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2018/10/25.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIGestureRecognizer+SAAutoTrack.h"
#import <objc/runtime.h>
#import "SASwizzle.h"
#import "SALog.h"

static void *const kSAGestureTargetKey = (void *)&kSAGestureTargetKey;
static void *const kSAGestureTargetActionModelsKey = (void *)&kSAGestureTargetActionModelsKey;

@implementation UIGestureRecognizer (SAAutoTrack)

#pragma mark - Hook Method
- (instancetype)sensorsdata_initWithTarget:(id)target action:(SEL)action {
    [self sensorsdata_initWithTarget:target action:action];
    self.sensorsdata_gestureTarget = [SAGestureTarget targetWithGesture:self];
    self.sensorsdata_targetActionModels = [NSMutableArray array];
    [self removeTarget:target action:action];
    [self addTarget:target action:action];
    return self;
}

- (void)sensorsdata_addTarget:(id)target action:(SEL)action {
    // Track 事件需要在原有事件之前触发(原有事件中更改页面内容,会导致部分内容获取不准确)
    if (self.sensorsdata_gestureTarget) {
        if (![SAGestureTargetActionModel containsObjectWithTarget:target andAction:action fromModels:self.sensorsdata_targetActionModels]) {
            SAGestureTargetActionModel *resulatModel = [[SAGestureTargetActionModel alloc] initWithTarget:target action:action];
            [self.sensorsdata_targetActionModels addObject:resulatModel];
            [self sensorsdata_addTarget:self.sensorsdata_gestureTarget action:@selector(trackGestureRecognizerAppClick:)];
        }
    }
    [self sensorsdata_addTarget:target action:action];
}

- (void)sensorsdata_removeTarget:(id)target action:(SEL)action {
    if (self.sensorsdata_gestureTarget) {
        SAGestureTargetActionModel *existModel = [SAGestureTargetActionModel containsObjectWithTarget:target andAction:action fromModels:self.sensorsdata_targetActionModels];
        if (existModel) {
            [self.sensorsdata_targetActionModels removeObject:existModel];
        }
    }
    [self sensorsdata_removeTarget:target action:action];
}

#pragma mark - Associated Object
- (SAGestureTarget *)sensorsdata_gestureTarget {
    return objc_getAssociatedObject(self, kSAGestureTargetKey);
}

- (void)setSensorsdata_gestureTarget:(SAGestureTarget *)sensorsdata_gestureTarget {
    objc_setAssociatedObject(self, kSAGestureTargetKey, sensorsdata_gestureTarget, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray <SAGestureTargetActionModel *>*)sensorsdata_targetActionModels {
    return objc_getAssociatedObject(self, kSAGestureTargetActionModelsKey);
}

- (void)setSensorsdata_targetActionModels:(NSMutableArray <SAGestureTargetActionModel *>*)sensorsdata_targetActionModels {
    objc_setAssociatedObject(self, kSAGestureTargetActionModelsKey, sensorsdata_targetActionModels, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
