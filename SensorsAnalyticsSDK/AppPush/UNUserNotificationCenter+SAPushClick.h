//
// UNUserNotificationCenter+SAPushClick.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface UNUserNotificationCenter (PushClick)

- (void)sensorsdata_setDelegate:(id <UNUserNotificationCenterDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
