//
// SASecretKey.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/6/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 密钥信息
@interface SASecretKey : NSObject <NSCoding, NSCopying>

/// 指定构造器，初始化时必须传入四个参数
/// @param key 非对称加密时使用的公钥值
/// @param version 非对称加密时使用的公钥值对应版本
/// @param asymmetricEncryptType 非对称加密类型
/// @param symmetricEncryptType 对称加密类型
/// @return 返回秘钥实例
- (instancetype)initWithKey:(NSString *)key
                    version:(NSInteger)version
      asymmetricEncryptType:(NSString *)asymmetricEncryptType
       symmetricEncryptType:(NSString *)symmetricEncryptType;

/// 禁用 init 初始化方法
- (instancetype)init NS_UNAVAILABLE;

/// 密钥版本
@property (nonatomic, assign, readonly) NSInteger version;

/// 密钥值
@property (nonatomic, copy, readonly) NSString *key;

/// 对称加密类型
@property (nonatomic, copy, readonly) NSString *symmetricEncryptType;

/// 非对称加密类型
@property (nonatomic, copy, readonly) NSString *asymmetricEncryptType;

@end

NS_ASSUME_NONNULL_END
