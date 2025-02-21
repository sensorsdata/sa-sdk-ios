//
// UIViewController+ExposureListener.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIViewController+ExposureListener.h"
#import "SAExposureViewObject.h"
#import "SAExposureManager.h"

@implementation UIViewController (SAExposureListener)

- (void)sensorsdata_exposure_viewDidAppear:(BOOL)animated {
    [self sensorsdata_exposure_viewDidAppear:animated];

    for (SAExposureViewObject *exposureViewObject in [SAExposureManager defaultManager].exposureViewObjects) {
        if (exposureViewObject.viewController == self) {
            [exposureViewObject findNearbyScrollView];
            [exposureViewObject exposureConditionCheck];
        }
    }
}

-(void)sensorsdata_exposure_viewDidDisappear:(BOOL)animated {
    [self sensorsdata_exposure_viewDidDisappear:animated];

    for (SAExposureViewObject *exposureViewObject in [SAExposureManager defaultManager].exposureViewObjects) {
        if (exposureViewObject.viewController == self) {
            exposureViewObject.state = SAExposureViewStateInvisible;
            exposureViewObject.lastExposure = 0;
            [exposureViewObject.timer stop];
        }
    }
}

@end
