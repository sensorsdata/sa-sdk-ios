//
// SensorsAnalyticsSDK+Deeplink.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK (Deeplink)

/**
DeepLink 回调函数
@param callback 请求成功后的回调函数
  params：创建渠道链接时填写的 App 内参数
  succes：deeplink 唤起结果
  appAwakePassedTime：获取渠道信息所用时间
*/
- (void)setDeeplinkCallback:(void(^)(NSString *_Nullable params, BOOL success, NSInteger appAwakePassedTime))callback API_UNAVAILABLE(macos);

/**
触发 $AppDeepLinkLaunch 事件
@param url 唤起 App 的 DeepLink url
*/
- (void)trackDeepLinkLaunchWithURL:(NSString *)url API_UNAVAILABLE(macos);

@end

@interface SAConfigOptions (Deeplink)

/// DeepLink 中解析出来的参数是否需要保存到本地
@property (nonatomic, assign) BOOL enableSaveDeepLinkInfo API_UNAVAILABLE(macos);

/// DeepLink 中用户自定义来源渠道属性 key 值，可传多个。
@property (nonatomic, copy) NSArray<NSString *> *sourceChannels API_UNAVAILABLE(macos);

@end

NS_ASSUME_NONNULL_END
