//
// SACommonUtility.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2018/7/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SACommonUtility : NSObject

///按字节截取指定长度字符，包括汉字和表情
+ (NSString *)subByteString:(NSString *)string byteLength:(NSInteger )length;

/// 主线程执行
+ (void)performBlockOnMainThread:(DISPATCH_NOESCAPE dispatch_block_t)block;

/// 获取当前的 UserAgent
+ (NSString *)currentUserAgent;

/// 保存 UserAgent
+ (void)saveUserAgent:(NSString *)userAgent;

/// 计算 hash
+ (NSString *)hashStringWithData:(NSData *)data;

#if TARGET_OS_IOS
/// $ios_install_source
+ (NSString *)appInstallSource;
#endif
@end
