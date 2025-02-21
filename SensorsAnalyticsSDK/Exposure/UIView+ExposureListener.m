//
// UIView+ExposureListener.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+ExposureListener.h"
#import "SAExposureManager.h"
#import <objc/runtime.h>
#import "NSObject+SAKeyValueObserver.h"
#import "UIView+SAInternalProperties.h"

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

- (void)sensorsdata_didMoveToWindow {
    [self sensorsdata_didMoveToWindow];
    if (!self.sensorsdata_exposureMark) {
        return;
    }
    SAExposureViewObject *exposureViewObject = [[SAExposureManager defaultManager] exposureViewWithView:self];
    [exposureViewObject findNearbyScrollView];
}

- (NSString *)sensorsdata_exposureMark {
    return objc_getAssociatedObject(self, kSAUIViewExposureMarkKey);
}

- (void)setSensorsdata_exposureMark:(NSString *)sensorsdata_exposureMark {
    objc_setAssociatedObject(self, kSAUIViewExposureMarkKey, sensorsdata_exposureMark, OBJC_ASSOCIATION_COPY);
}

@end

