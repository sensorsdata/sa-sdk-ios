//
// SAApplication.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAApplication : NSObject

+ (id)sharedApplication;
+ (BOOL)isAppExtension;

@end

NS_ASSUME_NONNULL_END
