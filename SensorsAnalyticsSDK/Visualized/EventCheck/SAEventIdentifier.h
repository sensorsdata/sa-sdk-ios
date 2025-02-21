//
// SAEventIdentifier.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/3/23.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAVisualPropertiesConfig.h"
#import "SensorsAnalyticsSDK+Private.h"

NS_ASSUME_NONNULL_BEGIN

/// 事件标识
@interface SAEventIdentifier : SAViewIdentifier

/// 事件名
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, strong) NSMutableDictionary *properties;

- (instancetype)initWithEventInfo:(NSDictionary *)eventInfo;

@end

NS_ASSUME_NONNULL_END
