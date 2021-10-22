//
// SANotificationManager.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/18.
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

#import "SAAppPushManager.h"
#import "SAApplicationDelegateProxy.h"
#import "SASwizzle.h"
#import "SALog.h"
#import "UIApplication+PushClick.h"
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

- (void)setConfigOptions:(SAConfigOptions *)configOptions {
    _configOptions = configOptions;
    [UIApplication sharedApplication].sensorsdata_launchOptions = configOptions.launchOptions;
    self.enable = configOptions.enableTrackPush;
}

- (void)proxyNotifications {
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
