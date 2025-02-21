//
// SAGestureTarget.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAGestureTarget : NSObject

+ (SAGestureTarget * _Nullable)targetWithGesture:(UIGestureRecognizer *)gesture;

- (void)trackGestureRecognizerAppClick:(UIGestureRecognizer *)gesture;

@end

NS_ASSUME_NONNULL_END
