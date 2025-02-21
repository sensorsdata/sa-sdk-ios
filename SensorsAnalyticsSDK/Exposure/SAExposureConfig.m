//
// SAExposureConfig.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAExposureConfig.h"

@interface SAExposureConfig () <NSCopying>

@property (nonatomic, assign) CGFloat areaRate;
@property (nonatomic, assign) NSTimeInterval stayDuration;
@property (nonatomic, assign) BOOL repeated;

@end

@implementation SAExposureConfig

- (instancetype)initWithAreaRate:(CGFloat)areaRate stayDuration:(NSTimeInterval)stayDuration repeated:(BOOL)repeated {
    self = [super init];
    if (self) {
        _areaRate = (areaRate >= 0 && areaRate <= 1 ? areaRate : 0);
        _stayDuration = (stayDuration >= 0 ? stayDuration : 0);
        _repeated = repeated;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone { 
    SAExposureConfig *config = [[[self class] allocWithZone:zone] init];
    config.areaRate = self.areaRate;
    config.stayDuration = self.stayDuration;
    config.repeated = self.repeated;
    return config;
}

@end
