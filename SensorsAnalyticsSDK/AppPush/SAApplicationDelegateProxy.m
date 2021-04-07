//
// SAApplicationDelegateProxy.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/7.
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

#import "SAApplicationDelegateProxy.h"
#import "SAClassHelper.h"
#import "NSObject+DelegateProxy.h"
#import "UIApplication+PushClick.h"
#import "SensorsAnalyticsSDK.h"
#import "SAAppPushConstants.h"
#import "SALog.h"
#import "SANotificationUtil.h"
#import <objc/message.h>

@implementation SAApplicationDelegateProxy

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    SEL selector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    [SAApplicationDelegateProxy invokeWithTarget:self selector:selector, application, userInfo, completionHandler];
    [SAApplicationDelegateProxy trackEventWithTarget:self application:application remoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    SEL selector = @selector(application:didReceiveLocalNotification:);
    [SAApplicationDelegateProxy invokeWithTarget:self selector:selector, application, notification];
    [SAApplicationDelegateProxy trackEventWithTarget:self application:application localNotification:notification];
}

+ (void)trackEventWithTarget:(NSObject *)target application:(UIApplication *)application remoteNotification:(NSDictionary *)userInfo {
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != application.delegate) {
        return;
    }
    //track notification
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        SALogInfo(@"iOS version >= 10.0, callback for %@ was ignored.", @"application:didReceiveRemoteNotification:fetchCompletionHandler:");
        return;
    }
    
    if (application.applicationState != UIApplicationStateInactive) {
        return;
    }
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[kSAEventPropertyNotificationChannel] = kSAEventPropertyNotificationChannelApple;
    
    if (userInfo) {
        NSString *title = nil;
        NSString *content = nil;
        id alert = userInfo[kSAPushAppleUserInfoKeyAps][kSAPushAppleUserInfoKeyAlert];
        if ([alert isKindOfClass:[NSDictionary class]]) {
            title = alert[kSAPushAppleUserInfoKeyTitle];
            content = alert[kSAPushAppleUserInfoKeyBody];
        } else if ([alert isKindOfClass:[NSString class]]) {
            content = alert;
        }
        if (userInfo[kSAPushServiceKeySF]) {
            properties[kSFMessageTitle] = title;
            properties[kSFMessageContent] = content;
        }
        properties[kSAEventPropertyNotificationTitle] = title;
        properties[kSAEventPropertyNotificationContent] = content;
        [properties addEntriesFromDictionary:[SANotificationUtil propertiesFromUserInfo:userInfo]];
    }
    
    [[SensorsAnalyticsSDK sharedInstance] track:kSAEventNameNotificationClick withProperties:properties];
}

+ (void)trackEventWithTarget:(NSObject *)target application:(UIApplication *)application localNotification:(UILocalNotification *)notification {
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != application.delegate) {
        return;
    }
    //track notification
    BOOL isValidPushClick = NO;
    if (application.applicationState == UIApplicationStateInactive) {
        isValidPushClick = YES;
    } else if (application.sensorsdata_launchOptions[UIApplicationLaunchOptionsLocalNotificationKey]) {
        isValidPushClick = YES;
        application.sensorsdata_launchOptions = nil;
    }
    
    if (!isValidPushClick) {
        SALogInfo(@"Invalid app push callback, AppPushClick was ignored.");
        return;
    }
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[kSAEventPropertyNotificationContent] = notification.alertBody;
    properties[kSFMessageContent] = notification.alertBody;
    properties[kSAEventPropertyNotificationServiceName] = kSAEventPropertyNotificationServiceNameLocal;
    
    if (@available(iOS 8.2, *)) {
        properties[kSAEventPropertyNotificationTitle] = notification.alertTitle;
        properties[kSFMessageTitle] = notification.alertTitle;
    }
    
    [[SensorsAnalyticsSDK sharedInstance] track:kSAEventNameNotificationClick withProperties:properties];
}

+ (NSSet<NSString *> *)optionalSelectors {
    return [NSSet setWithArray:@[@"application:didReceiveLocalNotification:", @"application:didReceiveRemoteNotification:fetchCompletionHandler:"]];
}

@end
