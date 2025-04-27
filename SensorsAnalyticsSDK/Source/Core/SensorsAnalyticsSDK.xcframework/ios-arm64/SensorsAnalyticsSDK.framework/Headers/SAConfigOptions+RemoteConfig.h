//
// SAConfigOptions+RemoteConfig.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAConfigOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (RemoteConfig)

#pragma mark - 请求远程配置策略
/// 请求远程配置地址，默认从 serverURL 解析
@property (nonatomic, copy) NSString *remoteConfigURL API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("RemoteConfig not supported for iOS extensions.");

/// 禁用随机时间请求远程配置
@property (nonatomic, assign) BOOL disableRandomTimeRequestRemoteConfig API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("RemoteConfig not supported for iOS extensions.");

/// 最小间隔时长，单位：小时，默认 24
@property (nonatomic, assign) NSInteger minRequestHourInterval API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("RemoteConfig not supported for iOS extensions.");

/// 最大间隔时长，单位：小时，默认 48
@property (nonatomic, assign) NSInteger maxRequestHourInterval API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("RemoteConfig not supported for iOS extensions.");

@end

NS_ASSUME_NONNULL_END
