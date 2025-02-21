//
// SAObject+SAConfigOptions.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/6/30.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SADatabase.h"
#import "SAConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface SADatabase (SAConfigOptions)

@property (nonatomic, assign, readonly) NSUInteger maxCacheSize;

@end

NS_ASSUME_NONNULL_END
