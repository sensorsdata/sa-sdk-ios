//
// SAEncryptSecretKeyHandler.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/6/18.
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

@class SASecretKey;
@class SAConfigOptions;

NS_ASSUME_NONNULL_BEGIN

@interface SAEncryptSecretKeyHandler : NSObject

/// 根据 ConfigOptions 初始化密钥管理类
/// @param configOptions SDK 初始化的 configOptions
- (instancetype)initWithConfigOptions:(SAConfigOptions *)configOptions NS_DESIGNATED_INITIALIZER;

/// 禁用 init 初始化
- (instancetype)init NS_UNAVAILABLE;

/// 禁用 new 初始化
+ (instancetype)new NS_UNAVAILABLE;

/// 保存公钥
/// @param secretKey 需要保存的公钥
- (void)saveSecretKey:(SASecretKey *)secretKey;

/// 获取公钥
- (SASecretKey *)loadSecretKey;

/// 校验加密公钥
/// @param url 打开本 App 的回调 url
- (void)checkSecretKeyURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
