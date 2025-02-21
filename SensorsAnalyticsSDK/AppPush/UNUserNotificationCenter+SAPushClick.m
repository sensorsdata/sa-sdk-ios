//
// UNUserNotificationCenter+SAPushClick.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UNUserNotificationCenter+SAPushClick.h"
#import "SAUNUserNotificationCenterDelegateProxy.h"

@implementation UNUserNotificationCenter (PushClick)

- (void)sensorsdata_setDelegate:(id<UNUserNotificationCenterDelegate>)delegate {
    //resolve optional selectors
    [SAUNUserNotificationCenterDelegateProxy resolveOptionalSelectorsForDelegate:delegate];
    
    [self sensorsdata_setDelegate:delegate];
    if (!self.delegate) {
        return;
    }
    [SAUNUserNotificationCenterDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"]]];
}

@end
