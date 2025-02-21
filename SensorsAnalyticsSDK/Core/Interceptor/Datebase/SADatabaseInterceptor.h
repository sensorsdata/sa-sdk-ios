//
// SADatabaseInterceptor.h
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/17.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAInterceptor.h"
#import "SAEventStore.h"
#import "SABaseEventObject.h"

NS_ASSUME_NONNULL_BEGIN

/// 数据库记录操作拦截器基类
@interface SADatabaseInterceptor : SAInterceptor

@property (nonatomic, strong, readonly) SAEventStore *eventStore;


@end

NS_ASSUME_NONNULL_END
