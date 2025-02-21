//
// SANetworkInfoPropertyPlugin.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2022/3/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPropertyPlugin.h"
#import "SAConstants+Private.h"

NS_ASSUME_NONNULL_BEGIN


/// 网络相关属性
@interface SANetworkInfoPropertyPlugin : SAPropertyPlugin

/// 当前的网络类型 (NS_OPTIONS)
/// @return 网络类型
- (SensorsAnalyticsNetworkType)currentNetworkTypeOptions;

/// 当前网络类型 (String)
/// @return 网络类型
- (NSString *)networkTypeString;

@end

NS_ASSUME_NONNULL_END
