//
// SAAppPageLeaveTracker.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/7/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//


#import "SAAppTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAPageLeaveObject : NSObject

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, copy) NSString *referrerURL;

@end

@interface SAAppPageLeaveTracker : SAAppTracker

@property (nonatomic, strong) NSMutableDictionary<NSString *, SAPageLeaveObject *> *pageLeaveObjects;

- (void)trackEvents;
- (void)trackPageEnter:(UIViewController *)viewController;
- (void)trackPageLeave:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
