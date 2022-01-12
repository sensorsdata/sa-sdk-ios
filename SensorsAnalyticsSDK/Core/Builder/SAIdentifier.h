//
// SAIdentifier.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/2/17.
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

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSAIdentitiesLoginId;

@interface SAIdentifier : NSObject

/// 用户的登录 Id
@property (nonatomic, copy, readonly) NSString *loginId;

/// 匿名 Id（设备 Id）：IDFA -> IDFV -> UUID
@property (nonatomic, copy, readonly) NSString *anonymousId;

/// 唯一用户标识：loginId -> 设备 Id
@property (nonatomic, copy, readonly) NSString *distinctId;

/// ID-Mapping 3.0 业务 ID，当前所有处理逻辑都是在的 serialQueue 中处理
@property (nonatomic, copy, readonly) NSDictionary *identities;

/// 自定义的 loginIDKey，
@property (nonatomic, copy, readonly) NSString *loginIDKey;

/**
 初始化方法

 @param queue 一个全局队列
 @param loginIDKey 自定义的 loginIDKey
 @return 初始化对象
 */
- (instancetype)initWithQueue:(dispatch_queue_t)queue loginIDKey:(NSString *)loginIDKey;

/**
 自定义匿名 Id（设备 Id）

 @param anonymousId 匿名 Id（设备 Id）
 @return 自定义匿名 ID 结果

 */
- (BOOL)identify:(NSString *)anonymousId;

/**
 重置匿名 Id
 */
- (void)resetAnonymousId;

/**
检查传入的 loginId 合法性

 @param loginId 设置的 loginId
 @return 合法性结果
*/
- (BOOL)isValidLoginId:(NSString *)loginId;

/**
 通过登录接口设置 loginId

 @param loginId 新的 loginId
 */
- (void)login:(NSString *)loginId;

/**
 通过退出登录接口删除本地的 loginId
 */
- (void)logout;

/**
 获取设备的 IDFA

 @return idfa
 */
+ (NSString *)idfa API_UNAVAILABLE(macos);

/**
 获取设备的 IDFV

 @return idfv
 */
+ (NSString *)idfv API_UNAVAILABLE(macos);

/**
 生成匿名 Id（设备 Id）：IDFA -> IDFV -> UUID

 @return 匿名 Id（设备 Id）
 */
+ (NSString *)hardwareID;

#pragma mark - Identities

/// 检查添业务 ID 是否有效，用于触发事件前判断
- (BOOL)isValidIdentity:(NSString *)key value:(NSString *)value;

/// 绑定业务 ID，需要在 serialQueue 中调用，同时绑定多个 ID 时数据
- (void)bindIdentity:(NSString *)key value:(NSString *)value;

/// 解绑业务 ID，需要在 serialQueue 中调用
- (void)unbindIdentity:(NSString *)key value:(NSString *)value;

/// 获取当前事件的业务 ID
- (NSDictionary *)identitiesWithEventType:(NSString *)eventType;

/// 用于合并 H5 传过来的业务 ID
- (NSDictionary *)mergeH5Identities:(NSDictionary *)identities eventType:(NSString *)eventType;

@end

NS_ASSUME_NONNULL_END
