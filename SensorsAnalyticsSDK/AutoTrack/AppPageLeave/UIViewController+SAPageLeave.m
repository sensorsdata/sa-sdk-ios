//
// UIViewController+PageView.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/7/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIViewController+SAPageLeave.h"
#import "SAAutoTrackManager.h"


@implementation UIViewController (SAPageLeave)

- (void)sensorsdata_pageLeave_viewDidAppear:(BOOL)animated {
    SAAppPageLeaveTracker *tracker = [SAAutoTrackManager defaultManager].appPageLeaveTracker;
    [tracker trackPageEnter:self];
    [self sensorsdata_pageLeave_viewDidAppear:animated];
}

- (void)sensorsdata_pageLeave_viewDidDisappear:(BOOL)animated {
    SAAppPageLeaveTracker *tracker = [SAAutoTrackManager defaultManager].appPageLeaveTracker;
    [tracker trackPageLeave:self];
    [self sensorsdata_pageLeave_viewDidDisappear:animated];
}



@end
