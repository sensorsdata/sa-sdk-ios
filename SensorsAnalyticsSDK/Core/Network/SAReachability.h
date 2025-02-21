//
// SAReachability.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/1/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if __has_include(<SystemConfiguration/SystemConfiguration.h>)

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

/**
 SAReachability 是参考 AFNetworkReachabilityManager 实现
 感谢 AFNetworking: https://github.com/AFNetworking/AFNetworking
 */
@interface SAReachability : NSObject

/// 是否有网络连接
@property (readonly, nonatomic, assign, getter = isReachable) BOOL reachable;

/// 当前的网络状态是否为 WIFI
@property (readonly, nonatomic, assign, getter = isReachableViaWiFi) BOOL reachableViaWiFi;

/// 当前的网络状态是否为 WWAN
@property (readonly, nonatomic, assign, getter = isReachableViaWWAN) BOOL reachableViaWWAN;

/// 获取网络触达类的实例
+ (instancetype)sharedInstance;

/// 开始监听网络状态
- (void)startMonitoring;

/// 停止监听网络状态
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END

#endif
