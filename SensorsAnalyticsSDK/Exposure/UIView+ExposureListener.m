//
// UIView+ExposureListener.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/10.
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

#import "UIView+ExposureListener.h"
#import "SAExposureManager.h"
#import <objc/runtime.h>
#import "NSObject+SAKeyValueObserver.h"

static void *const kSAUIViewExposureMarkKey = (void *)&kSAUIViewExposureMarkKey;

@implementation UIView (SAExposureListener)

- (void)sensorsdata_didMoveToSuperview {
    [self sensorsdata_didMoveToSuperview];
    if (!self.sensorsdata_exposureMark) {
        return;
    }
    SAExposureViewObject *exposureViewObject = [[SAExposureManager defaultManager] exposureViewWithView:self];
    if (!exposureViewObject) {
        return;
    }
    [exposureViewObject exposureConditionCheck];
}

- (NSString *)sensorsdata_exposureMark {
    return objc_getAssociatedObject(self, kSAUIViewExposureMarkKey);
}

- (void)setSensorsdata_exposureMark:(NSString *)sensorsdata_exposureMark {
    objc_setAssociatedObject(self, kSAUIViewExposureMarkKey, sensorsdata_exposureMark, OBJC_ASSOCIATION_COPY);
}

@end

