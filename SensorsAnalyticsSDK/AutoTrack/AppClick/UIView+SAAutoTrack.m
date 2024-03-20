//
// UIView+SAAutoTrack.m
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/6/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
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

#import "UIView+SAAutoTrack.h"
#import "SAAutoTrackUtils.h"
#import "SensorsAnalyticsSDK+Private.h"
#import <objc/runtime.h>
#import "SAViewElementInfoFactory.h"
#import "SAAutoTrackManager.h"
#import "SAUIProperties.h"
#import "UIView+SARNView.h"
#import "UIView+SensorsAnalytics.h"

static void *const kSALastAppClickIntervalPropertyName = (void *)&kSALastAppClickIntervalPropertyName;

#pragma mark - UIView

@implementation UIView (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    if (self.isHidden || self.sensorsAnalyticsIgnoreView) {
        return YES;
    }

    return [SAAutoTrackManager.defaultManager.appClickTracker isIgnoreEventWithView:self];
}

- (void)setSensorsdata_timeIntervalForLastAppClick:(NSTimeInterval)sensorsdata_timeIntervalForLastAppClick {
    objc_setAssociatedObject(self, kSALastAppClickIntervalPropertyName, [NSNumber numberWithDouble:sensorsdata_timeIntervalForLastAppClick], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)sensorsdata_timeIntervalForLastAppClick {
    return [objc_getAssociatedObject(self, kSALastAppClickIntervalPropertyName) doubleValue];
}

- (NSString *)sensorsdata_elementId {
    return self.sensorsAnalyticsViewID;
}

@end


#pragma mark - UIControl

@implementation UIControl (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    // 忽略 UITabBarItem
    BOOL ignoredUITabBarItem = [[SensorsAnalyticsSDK sdkInstance] isViewTypeIgnored:UITabBarItem.class] && [NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"];

    // 忽略 UIBarButtonItem
    BOOL ignoredUIBarButtonItem = [[SensorsAnalyticsSDK sdkInstance] isViewTypeIgnored:UIBarButtonItem.class] && ([NSStringFromClass(self.class) isEqualToString:@"UINavigationButton"] || [NSStringFromClass(self.class) isEqualToString:@"_UIButtonBarButton"]);

    return super.sensorsdata_isIgnored || ignoredUITabBarItem || ignoredUIBarButtonItem;
}

@end

@implementation UISegmentedControl (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    return super.sensorsdata_isIgnored || self.selectedSegmentIndex == UISegmentedControlNoSegment;
}

@end


@implementation UISlider (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    return self.tracking || super.sensorsdata_isIgnored;
}

@end
