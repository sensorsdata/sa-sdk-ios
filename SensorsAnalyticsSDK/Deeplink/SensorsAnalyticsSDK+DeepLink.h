//
// SensorsAnalyticsSDK+DeepLink.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/11.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "SensorsAnalyticsSDK.h"
#import "SASlinkCreator.h"
#import "SAAdvertisingConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface SADeepLinkObject : NSObject

/// DeepLink 获取归因数据时的应用内参数
@property (nonatomic, copy, nullable) NSString *params;

/// DeepLink 获取的归因数据，当前仅在 Deferred DeepLink 场景下存在
@property (nonatomic, copy, nullable) NSString *adChannels;

/// DeepLink 归因数据是否获取成功
@property (nonatomic, assign) BOOL success;

/// DeepLink 获取归因数据所用时间，单位毫秒
@property (nonatomic, assign) NSInteger appAwakePassedTime;

/// custom params
@property (nonatomic, copy, nullable) NSDictionary *customParams;

@end

@interface SensorsAnalyticsSDK (DeepLink)

/**
DeepLink 回调函数
@param callback 请求成功后的回调函数
  params：创建渠道链接时填写的 App 内参数
  succes：deepLink 唤起结果
  appAwakePassedTime：获取渠道信息所用时间
*/
- (void)setDeeplinkCallback:(void(^)(NSString *_Nullable params, BOOL success, NSInteger appAwakePassedTime))callback API_UNAVAILABLE(macos) __attribute__((deprecated("已过时，请参考 setDeepLinkCompletion"))) NS_EXTENSION_UNAVAILABLE("DeepLink not supported for iOS extensions.");

/**
触发 $AppDeepLinkLaunch 事件
@param url 唤起 App 的 DeepLink url
*/
- (void)trackDeepLinkLaunchWithURL:(NSString *)url API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("DeepLink not supported for iOS extensions.");

/**
手动触发 Deferred DeepLink 请求，需要在获取设备权限、网络权限后调用
@param properties 发送请求时自定义参数
*/
- (void)requestDeferredDeepLink:(NSDictionary *)properties API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("DeepLink not supported for iOS extensions.");

/**
 @abstract
 DeepLink 回调函数，包含 DeepLink 和 Deferred DeepLink 功能

 @discussion
  当前 API 在 DeepLink 和 Deferred DeepLink 场景下均可以正常使用。使用此 API 后无需再实现历史 API "setDeepLinkCallback"。
  若您同时实现了 setDeepLinkCompletion 和 setDeeplinkCallback 两个 API，SDK 内部也只会回调 setDeepLinkCompletion 回调函数。
 @param completion 唤起后的回调函数，当页面跳转成功时，completion 返回值 return YES，反之则 return NO
 */
- (void)setDeepLinkCompletion:(BOOL(^)(SADeepLinkObject *_Nullable obj))completion API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("DeepLink not supported for iOS extensions.");

@end

@interface SAConfigOptions (DeepLink)

/// DeepLink 中解析出来的参数是否需要保存到本地
@property (nonatomic, assign) BOOL enableSaveDeepLinkInfo API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("DeepLink not supported for iOS extensions.");

/// DeepLink 中用户自定义来源渠道属性 key 值，可传多个。
@property (nonatomic, copy) NSArray<NSString *> *sourceChannels API_UNAVAILABLE(macos);

/// 广告相关功能自定义地址
@property (nonatomic, copy) NSString *customADChannelURL API_UNAVAILABLE(macos);

@end

//
@interface SAConfigOptions (Advertising)

@property (nonatomic, copy) SAAdvertisingConfig *advertisingConfig;

@end

NS_ASSUME_NONNULL_END
