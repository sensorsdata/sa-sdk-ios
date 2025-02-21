//
// UIView+ExposureListener.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (SAExposureListener)

- (void)sensorsdata_didMoveToSuperview;
- (void)sensorsdata_didMoveToWindow;

@property (nonatomic, copy) NSString *sensorsdata_exposureMark;

@end

NS_ASSUME_NONNULL_END
