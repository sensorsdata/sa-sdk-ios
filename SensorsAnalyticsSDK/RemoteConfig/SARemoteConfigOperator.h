//
// SARemoteConfigOperator.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/11/1.
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

#import <Foundation/Foundation.h>
#import "SARemoteConfigModel.h"
#import "SensorsAnalyticsSDK+Private.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SARemoteConfigOperatorProtocol <NSObject>

@optional

/// 生效本地的远程配置
- (void)enableLocalRemoteConfig;

/// 尝试请求远程配置
- (void)tryToRequestRemoteConfig;

/// 删除远程配置请求
- (void)cancelRequestRemoteConfig;

/// 重试远程配置请求
/// @param isForceUpdate 是否强制请求最新的远程配置
- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate;

/// 处理远程配置的 URL
/// @param url 远程配置的 URL
- (BOOL)handleRemoteConfigURL:(NSURL *)url;

@end

/// 远程配置处理基类
@interface SARemoteConfigOperator : NSObject <SARemoteConfigOperatorProtocol>

@property (nonatomic, strong) SAConfigOptions *configOptions;
@property (atomic, strong) SARemoteConfigModel *model;
@property (nonatomic, assign, readonly) BOOL isDisableSDK;
/// 控制 AutoTrack 采集方式（-1 表示不修改现有的 AutoTrack 方式；0 代表禁用所有的 AutoTrack；其他 1～15 为合法数据）
@property (nonatomic, assign, readonly) NSInteger autoTrackMode;
@property (nonatomic, copy, readonly) NSString *project;

/// 初始化远程配置处理基类
/// @param configOptions 初始化 SDK 的配置参数
/// @param model 输入的远程配置模型
/// @return 远程配置处理基类的实例
- (instancetype)initWithConfigOptions:(SAConfigOptions *)configOptions remoteConfigModel:(nullable SARemoteConfigModel *)model;

/// 是否在事件黑名单中
/// @param event 输入的事件名
/// @return 是否在事件黑名单中
- (BOOL)isBlackListContainsEvent:(nullable NSString *)event;

/// 请求远程配置
/// @param isForceUpdate 是否请求最新的配置
/// @param completion 请求结果的回调
- (void)requestRemoteConfigWithForceUpdate:(BOOL)isForceUpdate completion:(void (^)(BOOL success, NSDictionary<NSString *, id> * _Nullable config))completion;

/// 从请求远程配置的返回结果中获取远程配置相关内容
/// @param config 请求远程配置的返回结果
/// @return 远程配置相关内容
- (NSDictionary<NSString *, id> *)extractRemoteConfig:(NSDictionary<NSString *, id> *)config;

/// 从请求远程配置的返回结果中获取加密相关内容
/// @param config 请求远程配置的返回结果
/// @return 加密相关内容
- (NSDictionary<NSString *, id> *)extractEncryptConfig:(NSDictionary<NSString *, id> *)config;

/// 触发 $AppRemoteConfigChanged 事件
/// @param remoteConfig 事件中的属性
- (void)trackAppRemoteConfigChanged:(NSDictionary<NSString *, id> *)remoteConfig;

/// 根据传入的内容生效远程配置
/// @param config 远程配置的内容
- (void)enableRemoteConfig:(NSDictionary *)config;

@end

NS_ASSUME_NONNULL_END
