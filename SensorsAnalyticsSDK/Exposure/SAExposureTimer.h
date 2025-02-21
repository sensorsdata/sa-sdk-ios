//
// SAExposureTimer.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAExposureTimer : NSObject

@property (nonatomic, copy, nullable) void (^completeBlock)(void);

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDuration:(NSTimeInterval)duration completeBlock:(nullable void (^)(void))completeBlock;

- (void)start;
- (void)stop;

- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
