//
// SANotificationUtil.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SANotificationUtil : NSObject

+ (NSDictionary *)propertiesFromUserInfo:(NSDictionary *)userInfo;

@end

@interface NSString (SFPushKey)

- (NSString *)sensorsdata_sfPushKey;

@end

NS_ASSUME_NONNULL_END
