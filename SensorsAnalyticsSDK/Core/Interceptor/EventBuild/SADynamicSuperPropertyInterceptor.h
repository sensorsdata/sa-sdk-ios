//
// SADynamicSuperPropertyInterceptor.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

/// 动态公共属性拦截器
///
/// 动态公共属性需要在 serialQueue 队列外获取，如果外部已采集并进入队列，就不再采集
@interface SADynamicSuperPropertyInterceptor : SAInterceptor

@end

NS_ASSUME_NONNULL_END
