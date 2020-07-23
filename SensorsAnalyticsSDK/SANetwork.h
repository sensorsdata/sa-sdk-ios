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

NS_ASSUME_NONNULL_BEGIN

typedef void(^SAURLSessionTaskCompletionHandler)(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error);

@interface SANetwork : NSObject

/// 用于评价请求是否是服务器信任的链接，默认为：defaultPolicy
@property (nonatomic, strong) SASecurityPolicy *securityPolicy;
/// 服务器的 URL
@property (nonatomic, strong) NSURL *serverURL;
/// debug mode
@property (nonatomic) SensorsAnalyticsDebugMode debugMode;

- (instancetype)initWithServerURL:(NSURL *)serverURL;

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
 通过 URLRequest 创建一个 task，并设置完成的回调

 @param request 请求对象
 @param completionHandler 完成回调
 @return 数据 task
 */
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(SAURLSessionTaskCompletionHandler)completionHandler;

/**
 将数据上传到 Sensors Analytics 的服务器上
 数据将同步发送，请在异步线程中调用

 @param events 事件的 json 字符串组成的数组
 @param isEncrypted 事件是否加密
 @return 同步返回数据是否上传成功
 */
- (BOOL)flushEvents:(NSArray<NSString *> *)events isEncrypted:(BOOL)isEncrypted;

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

/// 通过 serverURL 获取的 host
@property (nonatomic, copy, readonly, nullable) NSString *host;
/// 在 serverURL 中获取的 project 名称
@property (nonatomic, copy, readonly, nullable) NSString *project;
/// 在 serverURL 中获取的 token 名称
@property (nonatomic, copy, readonly, nullable) NSString *token;

- (BOOL)isSameProjectWithURLString:(NSString *)URLString;
- (BOOL)isValidServerURL;

@end

@interface SANetwork (SessionAndTask)

/**
 Sets a block to be executed when a connection level authentication challenge has occurred, as handled by the `NSURLSessionDelegate` method `URLSession:didReceiveChallenge:completionHandler:`.
 
 @param block A block object to be executed when a connection level authentication challenge has occurred. The block returns the disposition of the authentication challenge, and takes three arguments: the session, the authentication challenge, and a pointer to the credential that should be used to resolve the challenge.
 */
- (void)setSessionDidReceiveAuthenticationChallengeBlock:(nullable NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * _Nullable __autoreleasing * _Nullable credential))block;

/**
 Sets a block to be executed when a session task has received a request specific authentication challenge, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:didReceiveChallenge:completionHandler:`.
 
 @param block A block object to be executed when a session task has received a request specific authentication challenge. The block returns the disposition of the authentication challenge, and takes four arguments: the session, the task, the authentication challenge, and a pointer to the credential that should be used to resolve the challenge.
 */
- (void)setTaskDidReceiveAuthenticationChallengeBlock:(nullable NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * _Nullable __autoreleasing * _Nullable credential))block;

@end

NS_ASSUME_NONNULL_END
