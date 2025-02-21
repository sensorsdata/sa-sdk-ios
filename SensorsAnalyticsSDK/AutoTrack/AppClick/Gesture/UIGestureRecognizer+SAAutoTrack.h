//
// UIGestureRecognizer+SAAutoTrack.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2018/10/25.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SAAutoTrackProperty.h"
#import "SAGestureTarget.h"
#import "SAGestureTargetActionModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIGestureRecognizer (SAAutoTrack)

@property (nonatomic, strong, readonly) NSMutableArray <SAGestureTargetActionModel *>*sensorsdata_targetActionModels;
@property (nonatomic, strong, readonly) SAGestureTarget *sensorsdata_gestureTarget;

- (instancetype)sensorsdata_initWithTarget:(id)target action:(SEL)action;
- (void)sensorsdata_addTarget:(id)target action:(SEL)action;
- (void)sensorsdata_removeTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
