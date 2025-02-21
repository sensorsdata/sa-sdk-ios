//
// SAConfigOptions.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2019/4/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAStorePlugin.h"
#import "SAConstants.h"
#import "SAPropertyPlugin.h"

@class SASecretKey;
@class SASecurityPolicy;

NS_ASSUME_NONNULL_BEGIN

/**
 * @class
 *  SensorsAnalyticsSDK 初始化配置
 */
@interface SAConfigOptions : NSObject

/**
 指定初始化方法，设置 serverURL
 @param serverURL 数据接收地址
 @return 配置对象
 */
- (instancetype)initWithServerURL:(nonnull NSString *)serverURL
                    launchOptions:(nullable id)launchOptions NS_DESIGNATED_INITIALIZER;

/// 禁用 init 初始化
- (instancetype)init NS_UNAVAILABLE;

/// 禁用 new 初始化
+ (instancetype)new NS_UNAVAILABLE;

/**
 @abstract
 用于评估是否为服务器信任的安全链接。

 @discussion
 默认使用 defaultPolicy
 */
@property (nonatomic, strong) SASecurityPolicy *securityPolicy;

/**
 * @abstract
 * 设置 flush 时网络发送策略
 *
 * @discussion
 * 默认 3G、4G、WI-FI 环境下都会尝试 flush
 */
@property (nonatomic) SensorsAnalyticsNetworkType flushNetworkPolicy;

/**
 * @property
 *
 * @abstract
 * 两次数据发送的最小时间间隔，单位毫秒
 *
 * @discussion
 * 默认值为 15 * 1000 毫秒， 在每次调用 track 和 profileSet 等接口的时候，
 * 都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否 WIFI/3G/4G/5G 网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否超过 flushBulkSize
 * 如果满足这两个条件之一，则向服务器发送一次数据；如果都不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存10000条数据。
 */
@property (nonatomic) NSInteger flushInterval;

/**
 * @property
 *
 * @abstract
 * 本地缓存的最大事件数目，当累积日志量超过阈值时发送数据
 *
 * @discussion
 * 默认值为 100，在每次调用 track 和 profileSet 等接口的时候，都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否 WIFI/3G/4G/5G 网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否超过 flushBulkSize
 * 如果同时满足这两个条件，则向服务器发送一次数据；如果不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存 10000 条数据。
 */
@property (nonatomic) NSInteger flushBulkSize;

/// 设置本地缓存最多事件条数，默认为 10000 条事件
@property (nonatomic) NSInteger maxCacheSize;

/// 开启 log 打印
@property (nonatomic, assign) BOOL enableLog;

/// 禁用 SDK，默认为 NO
///
/// 禁用后，SDK 将不会触发事件，也不会发送网络请求
@property (nonatomic, assign) BOOL disableSDK;


/// App 进入后台时是否等待数据发送结果。默认 NO，不会等待数据发送结果；设置 YES，会等待数据发送结果
@property (nonatomic, assign) BOOL flushBeforeEnterBackground;

/// 是否进行 session 切割。默认 NO，不会进行 session 切割；设置 YES，会进行 session 切割
@property (nonatomic, assign) BOOL enableSession;

/// 设置 session 切割事件最大间隔时长，设置范围为正整数，单位为秒
@property (nonatomic, assign) NSInteger eventSessionTimeout;

/// 是否禁用采集 deviceId
@property (nonatomic, assign) BOOL disableDeviceId;

/// set instant events
@property (nonatomic, copy) NSArray<NSString *> *instantEvents;

/// 注册本地存储加密插件
///
/// 注册自定义加密插件，对本地存储加密，包括公共属性、用户 Id 等，不包括埋点事件
- (void)registerStorePlugin:(id<SAStorePlugin>)plugin;

/**
 * @abstract
 * 注册属性插件
 *
 * @param plugin 属性插件对象
 */
- (void)registerPropertyPlugin:(SAPropertyPlugin *)plugin;

/// 注册限制采集的敏感属性
- (void)registerLimitKeys:(NSDictionary<SALimitKey, NSString *> *)keys;

/// 自定义埋点数据存储路径
///
/// macOS 开发，针对多应用场景，可以使用相同数据库文件，确保每个应用触发 flush 后，上传所有埋点数据，使用 .plist 作为文件名后缀
@property (nonatomic, strong) NSString *databaseFilePath API_UNAVAILABLE(ios, tvos, watchos);


@end

NS_ASSUME_NONNULL_END
