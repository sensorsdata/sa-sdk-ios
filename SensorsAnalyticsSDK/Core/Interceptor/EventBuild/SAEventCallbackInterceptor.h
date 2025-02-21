//
// SAEventCallbackInterceptor.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^SAEventCallback)(NSString *event, NSMutableDictionary<NSString *, id> *properties);

@interface SAEventCallbackInterceptor : SAInterceptor

@end

NS_ASSUME_NONNULL_END
