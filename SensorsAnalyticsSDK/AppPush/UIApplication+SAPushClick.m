//
// UIApplication+SAPushClick.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIApplication+SAPushClick.h"
#import "SAApplicationDelegateProxy.h"
#import <objc/runtime.h>

static void *const kSALaunchOptions = (void *)&kSALaunchOptions;

@implementation UIApplication (PushClick)

- (void)sensorsdata_setDelegate:(id<UIApplicationDelegate>)delegate {
    //resolve optional selectors
    [SAApplicationDelegateProxy resolveOptionalSelectorsForDelegate:delegate];
    
    [self sensorsdata_setDelegate:delegate];
    
    if (!self.delegate) {
        return;
    }
    [SAApplicationDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"application:didReceiveLocalNotification:", @"application:didReceiveRemoteNotification:fetchCompletionHandler:"]]];
}

- (NSDictionary *)sensorsdata_launchOptions {
    return objc_getAssociatedObject(self, kSALaunchOptions);
}

- (void)setSensorsdata_launchOptions:(NSDictionary *)sensorsdata_launchOptions {
    objc_setAssociatedObject(self, kSALaunchOptions, sensorsdata_launchOptions, OBJC_ASSOCIATION_COPY);
}

@end
