//
//  SAConfigOptions.h
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2019/4/8.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import "SAConstants.h"

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
- (instancetype)initWithServerURL:(nonnull NSString *)serverURL launchOptions:(nullable id)launchOptions NS_DESIGNATED_INITIALIZER;

/// 禁用 init 初始化
- (instancetype)init NS_UNAVAILABLE;

/// 禁用 new 初始化
+ (instancetype)new NS_UNAVAILABLE;

/**
 * @property
 *
 * @abstract
 * 打开 SDK 自动追踪,默认只追踪 App 启动 / 关闭、进入页面、元素点击
 *
 * @discussion
 * 该功能自动追踪 App 的一些行为，例如 SDK 初始化、App 启动 / 关闭、进入页面 等等，具体信息请参考文档:
 *   https://sensorsdata.cn/manual/ios_sdk.html
 * 该功能默认关闭
 */
@property (nonatomic) SensorsAnalyticsAutoTrackEventType autoTrackEventType API_UNAVAILABLE(macos);

/// 是否自动采集子页面的页面浏览事件
///
/// 开启页面浏览事件采集时，有效。默认为不采集
@property (nonatomic) BOOL enableAutoTrackChildViewScreen API_UNAVAILABLE(macos);

/// 是否开启 WKWebView 的 H5 打通功能，该功能默认是关闭的
@property (nonatomic) BOOL enableJavaScriptBridge;

/// 是否自动收集 App Crash 日志，该功能默认是关闭的
@property (nonatomic) BOOL enableTrackAppCrash API_UNAVAILABLE(macos);

/**
 @abstract
 用于评估是否为服务器信任的安全链接。

 @discussion
 默认使用 defaultPolicy
 */
@property (nonatomic, strong) SASecurityPolicy *securityPolicy API_UNAVAILABLE(macos);

/**
 * @property
 *
 * @abstract
 * 两次数据发送的最小时间间隔，单位毫秒
 *
 * @discussion
 * 默认值为 15 * 1000 毫秒， 在每次调用 track、trackSignUp 以及 profileSet 等接口的时候，
 * 都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否 WIFI/3G/4G/5G 网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否达到 flushBulkSize
 * 如果满足这两个条件之一，则向服务器发送一次数据；如果都不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存10000条数据。
 */
@property (nonatomic) NSInteger flushInterval;

/**
 * @property
 *
 * @abstract
 * 本地缓存的最大事件数目，当累积日志量达到阈值时发送数据
 *
 * @discussion
 * 默认值为 100，在每次调用 track、trackSignUp 以及 profileSet 等接口的时候，都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否 WIFI/3G/4G/5G 网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否达到 flushBulkSize
 * 如果同时满足这两个条件，则向服务器发送一次数据；如果不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存 10000 条数据。
 */
@property (nonatomic) NSInteger flushBulkSize;

/// 设置本地缓存最多事件条数，默认为 10000 条事件
@property (nonatomic) NSInteger maxCacheSize;

/// 开启 log 打印
@property (nonatomic, assign) BOOL enableLog;

/// 开启点击图
@property (nonatomic, assign) BOOL enableHeatMap API_UNAVAILABLE(macos);

/// 开启可视化全埋点
@property (nonatomic, assign) BOOL enableVisualizedAutoTrack API_UNAVAILABLE(macos);

#pragma mark - 请求远程配置策略
/// 请求远程配置地址，默认从 serverURL 解析
@property (nonatomic, copy) NSString *remoteConfigURL API_UNAVAILABLE(macos);

/// 禁用随机时间请求远程配置
@property (nonatomic, assign) BOOL disableRandomTimeRequestRemoteConfig API_UNAVAILABLE(macos);

/// 最小间隔时长，单位：小时，默认 24
@property (nonatomic, assign) NSInteger minRequestHourInterval API_UNAVAILABLE(macos);

/// 最大间隔时长，单位：小时，默认 48
@property (nonatomic, assign) NSInteger maxRequestHourInterval API_UNAVAILABLE(macos);

/// DeepLink 中解析出来的参数是否需要保存到本地
@property (nonatomic, assign) BOOL enableSaveDeepLinkInfo API_UNAVAILABLE(macos);

/// DeepLink 中用户自定义来源渠道属性 key 值，可传多个。
@property (nonatomic, copy) NSArray<NSString *> *sourceChannels API_UNAVAILABLE(macos);

/// 是否在手动埋点事件中自动添加渠道匹配信息
@property (nonatomic, assign) BOOL enableAutoAddChannelCallbackEvent API_UNAVAILABLE(macos);

/// 当 App 进入后台时，是否执行 flush 将数据发送到 SensrosAnalytics，默认为 YES
@property (nonatomic, assign) BOOL flushBeforeEnterBackground;

/// 是否开启加密
@property (nonatomic, assign) BOOL enableEncrypt API_UNAVAILABLE(macos);

/// 存储公钥的回调。务必保存秘钥所有字段信息
@property (nonatomic, copy) void (^saveSecretKey)(SASecretKey * _Nonnull secretKey) API_UNAVAILABLE(macos);

/// 获取公钥的回调。务必回传秘钥所有字段信息
@property (nonatomic, copy) SASecretKey * _Nonnull (^loadSecretKey)(void) API_UNAVAILABLE(macos);

/// 是否开启多渠道匹配，开启后调用 profile_set,不开启则调用 profile_set_once
@property (nonatomic, assign) BOOL enableMultipleChannelMatch API_UNAVAILABLE(macos);

/// 开启前向页面标题采集功能，默认不开启
@property (nonatomic, assign) BOOL enableReferrerTitle API_UNAVAILABLE(macos);

///开启自动采集通知
@property (nonatomic, assign) BOOL enableTrackPush API_UNAVAILABLE(macos);

@end

NS_ASSUME_NONNULL_END
