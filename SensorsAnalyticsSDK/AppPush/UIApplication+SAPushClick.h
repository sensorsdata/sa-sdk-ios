//
// UIApplication+SAPushClick.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (PushClick)

- (void)sensorsdata_setDelegate:(id <UIApplicationDelegate>)delegate;
@property (nonatomic, copy, nullable) NSDictionary *sensorsdata_launchOptions;

@end

NS_ASSUME_NONNULL_END
