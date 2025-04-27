//
// UIView+ExposureIdentifier.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/22.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (SAExposureIdentifier)

@property (nonatomic, copy, nullable) NSString *exposureIdentifier;

@end

NS_ASSUME_NONNULL_END
