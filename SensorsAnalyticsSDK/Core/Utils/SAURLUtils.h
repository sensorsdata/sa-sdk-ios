//
// SAURLUtils.h
// SensorsAnalyticsSDK
//
// Created by 张敏超 on 2019/4/18.
/// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAConstants.h"

@interface SAURLUtils : NSObject

+ (NSString *)hostWithURL:(NSURL *)url;
+ (NSString *)hostWithURLString:(NSString *)URLString;

+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURL:(NSURL *)url;
+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURLString:(NSString *)URLString;

+ (NSString *)urlQueryStringWithParams:(NSDictionary <NSString *, NSString *> *)params;

/// 解码并解析 URL 参数
/// @param url url 对象
+ (NSDictionary<NSString *, NSString *> *)decodeQueryItemsWithURL:(NSURL *)url;

+ (NSURL *)buildServerURLWithURLString:(NSString *)urlString debugMode:(SensorsAnalyticsDebugMode)debugMode;
@end
