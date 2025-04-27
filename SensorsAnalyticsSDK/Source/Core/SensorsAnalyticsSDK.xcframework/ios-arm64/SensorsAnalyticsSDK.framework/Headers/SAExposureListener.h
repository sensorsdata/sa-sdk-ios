//
// SAExposureListener.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/4/18.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SAExposureData;

NS_ASSUME_NONNULL_BEGIN

@protocol SAExposureListener <NSObject>

@optional
- (BOOL)shouldExpose:(UIView *)view withData:(SAExposureData *)data;
- (void)didExpose:(UIView *)view withData:(SAExposureData *)data;

@end

NS_ASSUME_NONNULL_END
