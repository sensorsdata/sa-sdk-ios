//
// SACorrectUserIdInterceptor.h
// SensorsABTest
//
// Created by  储强盛 on 2022/6/13.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

/// 修正用户 Id
///
/// 兼容 AB 和 SF SDK 的用户 Id 修正逻辑
@interface SACorrectUserIdInterceptor : SAInterceptor

@end

NS_ASSUME_NONNULL_END
