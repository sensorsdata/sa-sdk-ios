//
// UIViewController+ExposureListener.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (SAExposureListener)

-(void)sensorsdata_exposure_viewDidAppear:(BOOL)animated;
-(void)sensorsdata_exposure_viewDidDisappear:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
