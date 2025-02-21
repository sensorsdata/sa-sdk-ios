//
// UIViewController+PageView.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/7/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (SAPageLeave)

- (void)sensorsdata_pageLeave_viewDidAppear:(BOOL)animated;

- (void)sensorsdata_pageLeave_viewDidDisappear:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
