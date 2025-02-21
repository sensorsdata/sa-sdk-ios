//
// SAPropertyPlugin+SAPrivate.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/24.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAPropertyPlugin ()

@property (nonatomic, strong, nullable) id<SAPropertyPluginEventFilter> filter;

@property (nonatomic, copy) NSDictionary<NSString *, id> *properties;
@property (nonatomic, copy) SAPropertyPluginHandler handler;

@end

NS_ASSUME_NONNULL_END
