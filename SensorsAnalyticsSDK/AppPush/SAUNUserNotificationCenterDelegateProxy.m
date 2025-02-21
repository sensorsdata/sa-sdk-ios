//
// SAUNUserNotificationCenterDelegateProxy.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAUNUserNotificationCenterDelegateProxy.h"
#import "SAClassHelper.h"
#import "NSObject+SADelegateProxy.h"
#import "SAAppPushConstants.h"
#import "SensorsAnalyticsSDK.h"
#import "SALog.h"
#import "SANotificationUtil.h"
#import <objc/message.h>

@implementation SAUNUserNotificationCenterDelegateProxy

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    SEL selector = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
    [SAUNUserNotificationCenterDelegateProxy invokeWithTarget:self selector:selector, center, response, completionHandler];
    [SAUNUserNotificationCenterDelegateProxy trackEventWithTarget:self notificationCenter:center notificationResponse:response];
}

+ (void)trackEventWithTarget:(NSObject *)target notificationCenter:(UNUserNotificationCenter *)center notificationResponse:(UNNotificationResponse *)response  API_AVAILABLE(ios(10.0)){
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != center.delegate) {
        return;
    }
    //track notification
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    UNNotificationRequest *request = response.notification.request;
    BOOL isRemoteNotification = [request.trigger isKindOfClass:[UNPushNotificationTrigger class]];
    if (isRemoteNotification) {
        properties[kSAEventPropertyNotificationChannel] = kSAEventPropertyNotificationChannelApple;
    } else {
        properties[kSAEventPropertyNotificationServiceName] = kSAEventPropertyNotificationServiceNameLocal;
    }
    
    properties[kSAEventPropertyNotificationTitle] = request.content.title;
    properties[kSAEventPropertyNotificationContent] = request.content.body;
    
    NSDictionary *userInfo = request.content.userInfo;
    if (userInfo) {
        [properties addEntriesFromDictionary:[SANotificationUtil propertiesFromUserInfo:userInfo]];
        if (userInfo[kSAPushServiceKeySF]) {
            properties[kSFMessageTitle] = request.content.title;
            properties[kSFMessageContent] = request.content.body;
        }
    }
    
    [[SensorsAnalyticsSDK sharedInstance] track:kSAEventNameNotificationClick withProperties:properties];
}

+ (NSSet<NSString *> *)optionalSelectors {
    return [NSSet setWithArray:@[@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"]];
}

@end
