//
//  UIApplication+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 17/3/22.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "UIApplication+AutoTrack.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK.h"
#import "UIView+SAHelpers.h"
#import "UIView+AutoTrack.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "UIViewController+AutoTrack.h"
#import "SAAutoTrackUtils.h"

@implementation UIApplication (AutoTrack)

- (BOOL)sa_sendAction:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event {

    /*
     默认先执行 AutoTrack
     如果先执行原点击处理逻辑，可能已经发生页面 push 或者 pop，导致获取当前 ViewController 不正确
     可以通过 UIView 扩展属性 sensorsAnalyticsAutoTrackAfterSendAction，来配置 AutoTrack 是发生在原点击处理函数之前还是之后
     */

    BOOL ret = YES;
    BOOL sensorsAnalyticsAutoTrackAfterSendAction = NO;

    @try {
        if ([from isKindOfClass:[UIView class]] && [(UIView *)from sensorsAnalyticsAutoTrackAfterSendAction]) {
            sensorsAnalyticsAutoTrackAfterSendAction = YES;
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
        sensorsAnalyticsAutoTrackAfterSendAction = NO;
    }

    if (sensorsAnalyticsAutoTrackAfterSendAction) {
        ret = [self sa_sendAction:action to:to from:from forEvent:event];
    }

    @try {
        /*
//         caojiangPreVerify:forEvent: & caojiangEventAction:forEvent: 是我们可视化埋点中的点击事件
//         这个地方如果不过滤掉，会导致 swizzle 多次，从而会触发多次 $AppClick 事件
//         caojiang 是我们 CTO 名字，我们相信这个前缀应该是唯一的
//         如果这个前缀还会重复，请您告诉我，我把我们架构师的名字也加上
//         */
//        if (![@"caojiangPreVerify:forEvent:" isEqualToString:NSStringFromSelector(action)] &&
//            ![@"caojiangEventAction:forEvent:" isEqualToString:NSStringFromSelector(action)]) {
            [self sa_track:action to:to from:from forEvent:event];
//        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }

    if (!sensorsAnalyticsAutoTrackAfterSendAction) {
        ret = [self sa_sendAction:action to:to from:from forEvent:event];
    }

    return ret;
}

- (void)sa_track:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event {
    // ViewType 被忽略
#if (defined SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS)
    if ([from isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
        return;
    } else if ([from isKindOfClass:NSClassFromString(@"UINavigationButton")] && [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UIBarButtonItem class]]) {
        return;
    } else
#else
    if ([to isKindOfClass:[UITabBar class]]) {
        return;
    } else
#endif
    if (![from conformsToProtocol:@protocol(SAAutoTrackViewProperty)] && ![to isKindOfClass:[UITabBarController class]]) {
        return;
    }

    BOOL isTabBar = [from isKindOfClass:[UITabBarItem class]] && [to isKindOfClass:[UITabBarController class]];

    NSObject<SAAutoTrackViewProperty> *object = (NSObject<SAAutoTrackViewProperty> *)from;
    NSMutableDictionary *properties = [SAAutoTrackUtils propertiesWithAutoTrackObject:object viewController:isTabBar ? (UITabBarController *)to : nil];
    if (!properties) {
        return;
    }

    if ([object isKindOfClass:[UISwitch class]] ||
        [object isKindOfClass:[UIStepper class]] ||
        [object isKindOfClass:[UISegmentedControl class]] ||
        [object isKindOfClass:[UITabBarItem class]]) {
        [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
        return;
    }

    if ([event isKindOfClass:[UIEvent class]] && event.type == UIEventTypeTouches && [[[event allTouches] anyObject] phase] == UITouchPhaseEnded) {
#if (defined SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS)
        if ([from isKindOfClass:NSClassFromString(@"UINavigationButton")]) {
            properties[SA_EVENT_PROPERTY_ELEMENT_TYPE] = @"UIBarButtonItem";
        }
#endif
        [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
        return;
    }

}

@end
