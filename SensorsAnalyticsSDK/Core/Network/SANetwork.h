//
// SANetwork.h
// SensorsAnalyticsSDK
//
// Created by 张敏超 on 2019/3/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SensorsAnalyticsSDK.h"
#import "SASecurityPolicy.h"
#import "SAHTTPSession.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^SAURLSessionTaskCompletionHandler)(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error);

@interface SANetwork : NSObject

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

@end

@interface SANetwork (ServerURL)

@property (nonatomic, copy, readonly) NSURL *serverURL;
/// 通过 serverURL 获取的 host
@property (nonatomic, copy, readonly, nullable) NSString *host;
/// 在 serverURL 中获取的 project 名称
@property (nonatomic, copy, readonly, nullable) NSString *project;
/// 在 serverURL 中获取的 token 名称
@property (nonatomic, copy, readonly, nullable) NSString *token;

@property (nonatomic, copy, readonly, nullable) NSURLComponents *baseURLComponents;

- (BOOL)isSameProjectWithURLString:(NSString *)URLString;
- (BOOL)isValidServerURL;

@end

NS_ASSUME_NONNULL_END
