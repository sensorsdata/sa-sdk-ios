//
// SARemoteConfigManager.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/11/5.
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

#import <Foundation/Foundation.h>
#import "SARemoteConfigCommonOperator.h"
#import "SARemoteConfigCheckOperator.h"

NS_ASSUME_NONNULL_BEGIN

/// 远程配置管理类
@interface SARemoteConfigManager : NSObject

@property (nonatomic, assign, readonly) BOOL isDisableSDK; // 是否禁用 SDK
@property (nonatomic, assign, readonly) NSInteger autoTrackMode; // 控制 AutoTrack 采集方式（-1 表示不修改现有的 AutoTrack 方式；0 代表禁用所有的 AutoTrack；其他 1～15 为合法数据）

/// 初始化远程配置管理类
/// @param options 远程配置处理参数
+ (void)startWithRemoteConfigOptions:(SARemoteConfigOptions *)options;

/// 获取远程配置管理类的实例
/// @return 远程配置管理类的实例
+ (instancetype)sharedInstance;

/// 生效本地远程配置
- (void)enableLocalRemoteConfig;

/// 请求远程配置
- (void)tryToRequestRemoteConfig;

/// 删除远程配置请求
- (void)cancelRequestRemoteConfig;

/// 重试远程配置请求
/// @param isForceUpdate 是否强制请求最新的远程配置
- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate;

/// 是否在事件黑名单中
/// @param event 输入的事件名
/// @return 是否在事件黑名单中
- (BOOL)isBlackListContainsEvent:(nullable NSString *)event;

/// 处理远程配置的 URL
/// @param url 远程配置的 URL
- (void)handleRemoteConfigURL:(NSURL *)url;

/// 是否为远程控制的 URL
/// @param url 输入的 URL
/// @return 是否为远程控制的 URL
- (BOOL)isRemoteConfigURL:(NSURL *)url;

/// 远程控制管理类能否处理该 URL
/// @param url 输入的 URL
/// @return 能否处理该 URL
- (BOOL)canHandleURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
