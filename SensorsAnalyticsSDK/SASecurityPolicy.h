//
//  SASecurityPolicy.h
//  SensorsAnalyticsSDK
//
//  Created by 张敏超 on 2019/3/9.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
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

typedef NS_ENUM(NSUInteger, SASSLPinningMode) {
    SASSLPinningModeNone,
    SASSLPinningModePublicKey,
    SASSLPinningModeCertificate,
};

NS_ASSUME_NONNULL_BEGIN

/**
 SASecurityPolicy 是参考 AFSecurityPolicy 实现
 使用方法与 AFSecurityPolicy 相同
 感谢 AFNetworking: https://github.com/AFNetworking/AFNetworking
 */
@interface SASecurityPolicy : NSObject <NSSecureCoding, NSCopying>

/// 证书验证类型，默认为：SASSLPinningModeNone
@property (readonly, nonatomic, assign) SASSLPinningMode SSLPinningMode;

/// 证书数据
@property (nonatomic, strong, nullable) NSSet <NSData *> *pinnedCertificates;

/// 是否信任无效或者过期证书，默认为：NO
@property (nonatomic, assign) BOOL allowInvalidCertificates;

/// 是否验证 domain
@property (nonatomic, assign) BOOL validatesDomainName;

/**
 从一个 Bundle 中获取证书

 @param bundle 目标 Bundle
 @return 证书数据
 */
+ (NSSet <NSData *> *)certificatesInBundle:(NSBundle *)bundle;

/**
 创建一个默认的验证对象

 @return 默认的对象
 */
+ (instancetype)defaultPolicy;

/**
 根据 mode 创建对象

 @param pinningMode 类型
 @return 初始化对象
 */
+ (instancetype)policyWithPinningMode:(SASSLPinningMode)pinningMode;

/**
 通过 mode 及 证书数据，初始化一个验证对象

 @param pinningMode mode
 @param pinnedCertificates 证书数据
 @return 初始化对象
 */
+ (instancetype)policyWithPinningMode:(SASSLPinningMode)pinningMode withPinnedCertificates:(NSSet <NSData *> *)pinnedCertificates;

/**
 是否通过验证

 一般在 `URLSession:didReceiveChallenge:completionHandler:` 和 `URLSession:task: didReceiveChallenge:completionHandler:` 两个回调方法中进行验证。

 @param serverTrust 服务端信任的证书
 @param domain 域名
 @return 是否信任
 */
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(nullable NSString *)domain;

@end

NS_ASSUME_NONNULL_END
