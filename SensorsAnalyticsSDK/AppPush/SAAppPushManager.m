//
// SANotificationManager.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAppPushManager.h"
#import "SAApplicationDelegateProxy.h"
#import "SASwizzle.h"
#import "SALog.h"
#import "UIApplication+SAPushClick.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAMethodHelper.h"
#import "SAConfigOptions+AppPush.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import "SAUNUserNotificationCenterDelegateProxy.h"
#endif

@implementation SAAppPushManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static SAAppPushManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAAppPushManager alloc] init];
    });
    return manager;
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    if (enable) {
        [self proxyNotifications];
    }
}

- (void)setConfigOptions:(SAConfigOptions *)configOptions NS_EXTENSION_UNAVAILABLE("AppPush not supported for iOS extensions.") {
    _configOptions = configOptions;
    [UIApplication sharedApplication].sensorsdata_launchOptions = configOptions.launchOptions;
    self.enable = configOptions.enableTrackPush;
}

- (void)proxyNotifications NS_EXTENSION_UNAVAILABLE("AppPush not supported for iOS extensions.") {
    //处理未实现代理方法也能采集事件的逻辑
    [SAMethodHelper swizzleRespondsToSelector];
    
    //UIApplicationDelegate proxy
    [SAApplicationDelegateProxy resolveOptionalSelectorsForDelegate:[UIApplication sharedApplication].delegate];
    [SAApplicationDelegateProxy proxyDelegate:[UIApplication sharedApplication].delegate selectors:[NSSet setWithArray:@[@"application:didReceiveLocalNotification:", @"application:didReceiveRemoteNotification:fetchCompletionHandler:"]]];
    
    //UNUserNotificationCenterDelegate proxy
    if (@available(iOS 10.0, *)) {
        if ([UNUserNotificationCenter currentNotificationCenter].delegate) {
            [SAUNUserNotificationCenterDelegateProxy proxyDelegate:[UNUserNotificationCenter currentNotificationCenter].delegate selectors:[NSSet setWithArray:@[@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"]]];
        }
        NSError *error = NULL;
        [UNUserNotificationCenter sa_swizzleMethod:@selector(setDelegate:) withMethod:@selector(sensorsdata_setDelegate:) error:&error];
        if (error) {
            SALogError(@"proxy notification delegate error: %@", error);
        }
    }
}

@end
