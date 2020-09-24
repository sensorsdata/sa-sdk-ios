//
// SAChannelMatchManager.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/8/29.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAConfigOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAChannelMatchManager : NSObject

/// 激活事件是否开启多渠道匹配，开启后调用 profile_set , 不开启则调用 profile_set_once
@property (nonatomic, assign) BOOL enableMultipleChannelMatch;

+ (instancetype)sharedInstance;

/**
 * @abstract
 * 用于在 App 首次启动时追踪渠道来源，并设置追踪渠道事件的属性。SDK 会将渠道值填入事件属性 $utm_ 开头的一系列属性中。
 *
 * @param event  event 的名称
 * @param propertyDict     event 的属性
 * @param disableCallback     是否关闭这次渠道匹配的回调请求
*/
- (void)trackInstallation:(NSString *)event properties:(NSDictionary *)propertyDict disableCallback:(BOOL)disableCallback;

/**
 * @abstract
 * 用于检查当前唤起 App 的 URL 是否为有效的渠道联调诊断功能链接
 *
 * @param url 唤起 App 的链接
*/
- (BOOL)canHandleURL:(NSURL *)url;

/**
 * @abstract
 * 展示渠道联调诊断功能的授权弹窗
 *
 * @param url 唤起 App 的链接
*/
- (void)showAuthorizationAlertWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
