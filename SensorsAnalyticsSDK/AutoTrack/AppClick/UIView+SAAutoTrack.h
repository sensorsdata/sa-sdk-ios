//
// UIView+SAAutoTrack.h
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/6/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SAAutoTrackProperty.h"

#pragma mark - UIView

@interface UIView (AutoTrack) <SAAutoTrackViewProperty>
@end

#pragma mark - UIControl

@interface UIControl (AutoTrack) <SAAutoTrackViewProperty>
@end

@interface UISegmentedControl (AutoTrack) <SAAutoTrackViewProperty>
@end


@interface UISlider (AutoTrack) <SAAutoTrackViewProperty>
@end
