//
// UIViewController+SAAutoTrack.h
// SensorsAnalyticsSDK
//
// Created by 王灼洲 on 2017/10/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SAAutoTrackProperty.h"

@interface UIViewController (AutoTrack) <SAAutoTrackViewControllerProperty>

- (void)sa_autotrack_viewDidAppear:(BOOL)animated;

@end

@interface UINavigationController (AutoTrack)

/// 上一次页面，防止侧滑/下滑重复采集 $AppViewScreen 事件
@property (nonatomic, strong) UIViewController *sensorsdata_previousViewController;

@end
