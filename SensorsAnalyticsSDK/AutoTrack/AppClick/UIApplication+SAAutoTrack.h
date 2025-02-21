//
// UIApplication+SAAutoTrack.h
// SensorsAnalyticsSDK
//
// Created by 王灼洲 on 17/3/22.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (AutoTrack)

- (BOOL)sa_sendAction:(SEL)action
                   to:(nullable id)to
                 from:(nullable id)from
             forEvent:(nullable UIEvent *)event;

@end

NS_ASSUME_NONNULL_END
