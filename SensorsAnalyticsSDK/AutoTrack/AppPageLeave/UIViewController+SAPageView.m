//
// UIViewController+PageView.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/7/19.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "UIViewController+SAPageView.h"
#import "SAAutoTrackManager.h"


@implementation UIViewController (PageLeave)

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
