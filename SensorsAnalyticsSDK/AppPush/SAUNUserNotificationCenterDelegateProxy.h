//
// SAUNUserNotificationCenterDelegateProxy.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SADelegateProxy.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SAUNUserNotificationCenterDelegateProxy : SADelegateProxy



@end

NS_ASSUME_NONNULL_END
