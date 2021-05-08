//
// SASecretKeyFactory.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/20.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SASecretKeyFactory.h"
#import "SAConfigOptions.h"
#import "SAConfigOptions+Private.h"
#import "SAValidator.h"
#import "SAJSONUtil.h"
#import "SAECCEncryptor.h"
#import "SAAESEncryptor.h"
#import "SARSAEncryptor.h"

@implementation SASecretKeyFactory

+ (SASecretKey *)generateSecretKeyWithRemoteConfig:(NSDictionary *)remoteConfig {
    if (!remoteConfig) {
        return nil;
    }
    NSString *customContent = remoteConfig[@"key_custom_placeholder"];
    if ([SAValidator isValidString:customContent]) {
        // 当自定义插件秘钥字段存在时，不再使用其他加密插件
        // 不论秘钥是否创建成功，都不再切换使用其他加密插件
        NSDictionary *config = [SAJSONUtil objectFromJSONString:customContent];
        SASecretKey *secretKey = [self createCustomSecretKey:config];
        return secretKey;
    }

    NSString *eccContent = remoteConfig[@"key_ec"];
    if (eccContent && NSClassFromString(kSAEncryptECCClassName)) {
        // 当 key_ec 存在且加密库存在时，使用 ECC 加密插件
        // 不论秘钥是否创建成功，都不再切换使用其他加密插件
        NSDictionary *config = [SAJSONUtil objectFromJSONString:eccContent];
        SASecretKey *secretKey = [self createECCSecretKey:config];
        return secretKey;
    }

    // 当远程配置不包含自定义秘钥且 ECC 不可用时，使用 RSA 秘钥
    return [self createRSASecretKey:remoteConfig];
}

+ (SASecretKey *)createCustomSecretKey:(NSDictionary *)config {
    if (![SAValidator isValidDictionary:config]) {
        return nil;
    }
    // 暂不支持自定义秘钥类型
    SASecretKey *secretKey = [[SASecretKey alloc] init];
    return secretKey;
}

+ (SASecretKey *)createECCSecretKey:(NSDictionary *)config {
    if (![SAValidator isValidDictionary:config]) {
        return nil;
    }
    NSNumber *pkv = config[@"pkv"];
    NSString *publicKey = config[@"public_key"];
    NSString *type = config[@"type"];
    if (!pkv || ![SAValidator isValidString:type] || ![SAValidator isValidString:publicKey]) {
        return nil;
    }
    SASecretKey *secretKey = [[SASecretKey alloc] init];
    secretKey.version = [pkv integerValue];
    secretKey.asymmetricEncryptType = type;
    secretKey.symmetricEncryptType = kSAAlgorithmTypeAES;
    secretKey.key = [NSString stringWithFormat:@"%@:%@", type, publicKey];
    return secretKey;
}

+ (SASecretKey *)createRSASecretKey:(NSDictionary *)config {
    if (![SAValidator isValidDictionary:config]) {
        return nil;
    }
    NSNumber *pkv = config[@"pkv"];
    NSString *publicKey = config[@"public_key"];
    if (!pkv || ![SAValidator isValidString:publicKey]) {
        return nil;
    }
    SASecretKey *secretKey = [[SASecretKey alloc] init];
    secretKey.version = [pkv integerValue];
    secretKey.key = publicKey;
    secretKey.asymmetricEncryptType = kSAAlgorithmTypeRSA;
    secretKey.symmetricEncryptType = kSAAlgorithmTypeAES;
    return secretKey;
}

@end
