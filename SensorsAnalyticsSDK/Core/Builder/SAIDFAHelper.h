//
// SAIDFAHelper.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/12/1.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAIDFAHelper : NSObject

/**
 获取设备的 IDFA

 @return idfa
 */
+ (nullable NSString *)idfa;

@end

NS_ASSUME_NONNULL_END
