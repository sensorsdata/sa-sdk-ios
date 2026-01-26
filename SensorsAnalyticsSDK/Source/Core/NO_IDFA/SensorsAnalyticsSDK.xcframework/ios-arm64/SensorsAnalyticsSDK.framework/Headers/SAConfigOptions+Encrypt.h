//
// SAConfigOptions+Encrypt.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAEncryptProtocol.h"
#import "SAConfigOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (Encrypt)

/// 是否开启埋点数据入库加密
@property (nonatomic, assign) BOOL enableEncrypt API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("Encrypt not supported for iOS extensions.");

/// 是否开启埋点数据上报传输加密
@property (nonatomic, assign) BOOL enableTransportEncrypt API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("Encrypt not supported for iOS extensions.");

/// 注册埋点加密插件
- (void)registerEncryptor:(id<SAEncryptProtocol>)encryptor API_UNAVAILABLE(macos);

/// 存储公钥的回调。务必保存秘钥所有字段信息
@property (nonatomic, copy) void (^saveSecretKey)(SASecretKey * _Nonnull secretKey) API_UNAVAILABLE(macos);

/// 获取公钥的回调。务必回传秘钥所有字段信息
@property (nonatomic, copy) SASecretKey * _Nonnull (^loadSecretKey)(void) API_UNAVAILABLE(macos);

@end

NS_ASSUME_NONNULL_END
