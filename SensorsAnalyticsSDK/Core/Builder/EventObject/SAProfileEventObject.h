//
// SAProfileEventObject.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/13.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SABaseEventObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAProfileEventObject : SABaseEventObject

- (instancetype)initWithType:(NSString *)type NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

@interface SAProfileIncrementEventObject : SAProfileEventObject

@end

@interface SAProfileAppendEventObject : SAProfileEventObject

@end

NS_ASSUME_NONNULL_END
