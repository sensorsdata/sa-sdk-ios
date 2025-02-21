//
// SASecretKeyFactory.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/20.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SASecretKeyFactory.h"
#import "SAConfigOptions.h"
#import "SASecretKey.h"
#import "SAValidator.h"
#import "SAJSONUtil.h"
#import "SAAlgorithmProtocol.h"
#import "SAECCPluginEncryptor.h"

static NSString *const kSAEncryptVersion = @"pkv";
static NSString *const kSAEncryptPublicKey = @"public_key";
static NSString *const kSAEncryptType = @"type";
static NSString *const kSAEncryptTypeSeparate = @"+";

@implementation SASecretKeyFactory

#pragma mark - Encryptor Plugin 2.0
+ (SASecretKey *)createSecretKeyByVersion2:(NSDictionary *)version2 {
    // key_v2 不存在时直接跳过 2.0 逻辑
    if (!version2) {
        return nil;
    }

    NSNumber *pkv = version2[kSAEncryptVersion];
    NSString *type = version2[kSAEncryptType];
    NSString *publicKey = version2[kSAEncryptPublicKey];

    // 检查相关参数是否有效
    if (!pkv || ![SAValidator isValidString:type] || ![SAValidator isValidString:publicKey]) {
        return nil;
    }

    NSArray *types = [type componentsSeparatedByString:kSAEncryptTypeSeparate];
    // 当 type 分隔数组个数小于 2 时 type 不合法，不处理秘钥信息
    if (types.count < 2) {
        return nil;
    }

    // 非对称加密类型，例如: SM2
    NSString *asymmetricType = types[0];

    // 对称加密类型，例如: SM4
    NSString *symmetricType = types[1];

    return [[SASecretKey alloc] initWithKey:publicKey version:[pkv integerValue] asymmetricEncryptType:asymmetricType symmetricEncryptType:symmetricType];
}

+ (SASecretKey *)createSecretKeyByVersion1:(NSDictionary *)version1 {
    if (!version1) {
        return nil;
    }
    // 1.0 历史版本逻辑，只处理 key 字段中内容
    NSString *eccContent = version1[@"key_ec"];

    // 当 key_ec 存在且加密库存在时，使用 EC 加密插件
    // 不论秘钥是否创建成功，都不再切换使用其他加密插件

    // 这里为了检查 ECC 插件是否存在，手动生成 ECC 模拟秘钥
    if (eccContent && [SAECCPluginEncryptor isAvaliable]) {
        NSDictionary *config = [SAJSONUtil JSONObjectWithString:eccContent];
        return [SASecretKeyFactory createECCSecretKey:config];
    }

    // 当远程配置不包含自定义秘钥且 EC 不可用时，使用 RSA 秘钥
    return [SASecretKeyFactory createRSASecretKey:version1];
}

#pragma mark - Encryptor Plugin 1.0
+ (SASecretKey *)createECCSecretKey:(NSDictionary *)config {
    if (![SAValidator isValidDictionary:config]) {
        return nil;
    }
    NSNumber *pkv = config[kSAEncryptVersion];
    NSString *publicKey = config[kSAEncryptPublicKey];
    NSString *type = config[kSAEncryptType];
    if (!pkv || ![SAValidator isValidString:type] || ![SAValidator isValidString:publicKey]) {
        return nil;
    }
    NSString *key = [NSString stringWithFormat:@"%@:%@", type, publicKey];
    return [[SASecretKey alloc] initWithKey:key version:[pkv integerValue] asymmetricEncryptType:type symmetricEncryptType:kSAAlgorithmTypeAES];
}

+ (SASecretKey *)createRSASecretKey:(NSDictionary *)config {
    if (![SAValidator isValidDictionary:config]) {
        return nil;
    }
    NSNumber *pkv = config[kSAEncryptVersion];
    NSString *publicKey = config[kSAEncryptPublicKey];
    if (!pkv || ![SAValidator isValidString:publicKey]) {
        return nil;
    }
    return [[SASecretKey alloc] initWithKey:publicKey version:[pkv integerValue] asymmetricEncryptType:kSAAlgorithmTypeRSA symmetricEncryptType:kSAAlgorithmTypeAES];
}

@end
