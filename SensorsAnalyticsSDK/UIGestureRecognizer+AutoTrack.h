//
//  UIGestureRecognizer+AutoTrack.h
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2018/10/25.
//  Copyright © 2018 Sensors Data Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIGestureRecognizer (AutoTrack)

@end


@interface UITapGestureRecognizer (AutoTrack)

- (instancetype)sa_initWithTarget:(id)target action:(SEL)action;

- (void)sa_addTarget:(id)target action:(SEL)action;

@end


@interface UILongPressGestureRecognizer (AutoTrack)

- (instancetype)sa_initWithTarget:(id)target action:(SEL)action;

- (void)sa_addTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
