//
// SAEventBuildStrategy.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/15.
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SAEventBuildStrategyProtocol <NSObject>

/// 添加事件属性
/// @param properties 事件属性
- (void)addEventProperties:(NSDictionary *)properties;

/// 添加渠道信息
/// @param properties 渠道信息
- (void)addChannelProperties:(NSDictionary *)properties;

/// 添加 SDK 模块中的预置属性
/// @param properties SDK 模块中的预置属性
- (void)addModuleProperties:(NSDictionary *)properties;

/// 添加公共属性
/// @param properties 公共属性
- (void)addSuperProperties:(NSDictionary *)properties;

/// 添加自定义属性(属性校验不通过时, error 包含错误信息)
/// @param properties 自定义属性
- (void)addCustomProperties:(NSDictionary *)properties error:(NSError ** _Nullable)error;

/// 添加前向页面标题
/// @param referrerTitle 前向页面标题
- (void)addReferrerTitleProperty:(NSString *)referrerTitle;

/// 添加事件时长
/// @param duration 事件时长
- (void)addDurationProperty:(NSNumber *)duration;

@end

NS_ASSUME_NONNULL_END
