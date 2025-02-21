//
// UIView+SAElementType.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAUIViewElementProperties.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (SAElementType) <SAUIViewElementProperties>

@end

@interface UIControl (SAElementType) <SAUIViewElementProperties>

@end

NS_ASSUME_NONNULL_END
