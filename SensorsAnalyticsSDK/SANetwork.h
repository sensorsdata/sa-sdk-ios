//
//  SANetwork.h
//  SensorsAnalyticsSDK
//
//  Created by 张敏超 on 2019/3/8.
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
#import "SensorsAnalyticsSDK.h"
#import "SASecurityPolicy.h"
#import "SAHTTPSession.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^SAURLSessionTaskCompletionHandler)(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error);

@interface SANetwork : NSObject

/// 用于评价请求是否是服务器信任的链接，默认为：defaultPolicy
@property (nonatomic, strong) SASecurityPolicy *securityPolicy;
/// debug mode
@property (nonatomic) SensorsAnalyticsDebugMode debugMode;

/**
 * @abstract
 * 设置 Cookie
 *
 * @param cookie NSString cookie
 * @param encode BOOL 是否 encode
 */
- (void)setCookie:(NSString *)cookie isEncoded:(BOOL)encode;

/**
 * @abstract
 * 返回已设置的 Cookie
 *
 * @param decode BOOL 是否 decode
 * @return NSString cookie
 */
- (NSString *)cookieWithDecoded:(BOOL)decode;

/**
 设置 DebugMode 时回调请求方法

 @param distinctId 设备 ID 或 登录 ID
 @param params 扫码得到的参数
 @return request task
 */
- (nullable NSURLSessionTask *)debugModeCallbackWithDistinctId:(NSString *)distinctId params:(NSDictionary<NSString *, id> *)params;

/**
 请求远程配置

 @param version 远程配置的 version
 @param completion 结束的回调
 @return request task
 */
- (nullable NSURLSessionTask *)functionalManagermentConfigWithRemoteConfigURL:(nullable NSURL *)remoteConfigURL version:(NSString *)version completion:(void(^)(BOOL success, NSDictionary<NSString *, id> *config))completion;

@end

@interface SANetwork (ServerURL)

@property (nonatomic, copy, readonly) NSURL *serverURL;
/// 通过 serverURL 获取的 host
@property (nonatomic, copy, readonly, nullable) NSString *host;
/// 在 serverURL 中获取的 project 名称
@property (nonatomic, copy, readonly, nullable) NSString *project;
/// 在 serverURL 中获取的 token 名称
@property (nonatomic, copy, readonly, nullable) NSString *token;

- (BOOL)isSameProjectWithURLString:(NSString *)URLString;
- (BOOL)isValidServerURL;

@end

NS_ASSUME_NONNULL_END
