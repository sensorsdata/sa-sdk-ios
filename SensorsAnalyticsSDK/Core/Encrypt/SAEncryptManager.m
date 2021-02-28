//
// SAEncryptManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/11/25.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAEncryptManager.h"
#import "SAConfigOptions.h"
#import "SAValidator.h"
#import "SAURLUtils.h"
#import "SAAlertController.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAFileStore.h"
#import "SAJSONUtil.h"
#import "SAGzipUtility.h"
#import "SAAESEncryptor.h"
#import "SARSAEncryptor.h"
#import "SAECCEncryptor.h"
#import "SALog.h"

static NSString * const kSAEncryptSecretKey = @"SAEncryptSecretKey";

@interface SAEncryptManager ()

/// 数据加密器（使用 AES 加密数据）
@property (nonatomic, strong) SAAbstractEncryptor *dataEncryptor;

/// 数据加密器的原始密钥（原始的 AES 密钥）
@property (atomic, copy) NSData *originalAESKey;

/// 数据加密器的加密后密钥（加密后的 AES 密钥）
@property (atomic, copy) NSString *encryptedAESKey;

/// 密钥加密器（使用 RSA/ECC 加密 AES 密钥）
@property (nonatomic, strong) SAAbstractEncryptor *keyEncryptor;

/// 密钥加密器的公钥（RSA/ECC 的公钥）
@property (nonatomic, strong) SASecretKey *secretKey;

@end

@implementation SAEncryptManager

#pragma mark - SAModuleProtocol

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        [self updateEncryptor];
    }
}

#pragma mark - SAOpenURLProtocol

- (BOOL)canHandleURL:(nonnull NSURL *)url {
    return [url.host isEqualToString:@"encrypt"];
}

- (BOOL)handleURL:(nonnull NSURL *)url {
    NSString *message = @"当前 App 未开启加密，请开启加密后再试";

    if (self.enable) {
        NSDictionary *paramDic = [SAURLUtils queryItemsWithURL:url];
        NSString *urlVersion = paramDic[@"v"];
        NSString *urlKey = paramDic[@"key"];

        if ([SAValidator isValidString:urlVersion] && [SAValidator isValidString:urlKey]) {
            SASecretKey *secretKey = [self loadCurrentSecretKey];
            NSString *loadVersion = [@(secretKey.version) stringValue];
            // url 中的 key 为 encode 之后的
            NSString *loadKey = [secretKey.key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];

            if ([loadVersion isEqualToString:urlVersion] && [loadKey isEqualToString:urlKey]) {
                message = @"密钥验证通过，所选密钥与 App 端密钥相同";
            } else if (![SAValidator isValidString:loadKey]) {
                message = @"密钥验证不通过，App 端密钥为空";
            } else {
                message = [NSString stringWithFormat:@"密钥验证不通过，所选密钥与 App 端密钥不相同。所选密钥版本:%@，App 端密钥版本:%@", urlVersion, loadVersion];
            }
        } else {
            message = @"密钥验证不通过，所选密钥无效";
        }
    }

    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:nil message:message preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleDefault handler:nil];
    [alertController show];
    return YES;
}

#pragma mark - SAEncryptModuleProtocol

- (BOOL)hasSecretKey {
    return self.dataEncryptor && self.keyEncryptor;
}

- (void)handleEncryptWithConfig:(NSDictionary *)encryptConfig {
    if (!encryptConfig) {
        return;
    }

    SASecretKey *secretKey = [[SASecretKey alloc] init];
    NSString *ecKey = encryptConfig[@"key_ec"];
    if ([SAValidator isValidString:ecKey] && NSClassFromString(kSAEncryptECCClassName)) {
        // 获取 ECC 密钥
        NSData *data = [ecKey dataUsingEncoding:NSUTF8StringEncoding];
        if (!data) {
            return;
        }

        NSDictionary *ecKeyDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![SAValidator isValidDictionary:ecKeyDic]) {
            return;
        }

        NSNumber *pkv = ecKeyDic[@"pkv"];
        NSString *type = ecKeyDic[@"type"];
        NSString *publicKey = ecKeyDic[@"public_key"];
        if (!pkv || ![SAValidator isValidString:type] || ![SAValidator isValidString:publicKey]) {
            return;
        }

        secretKey.version = [pkv integerValue];
        secretKey.key = [NSString stringWithFormat:@"%@:%@", type, publicKey];
    } else {
        // 获取 RSA 密钥
        NSNumber *pkv = encryptConfig[@"pkv"];
        NSString *publicKey = encryptConfig[@"public_key"];
        if (!pkv || ![SAValidator isValidString:publicKey]) {
            return;
        }

        secretKey.version = [pkv integerValue];
        secretKey.key = publicKey;
    }

    // 存储请求的公钥
    [self saveRequestSecretKey:secretKey];

    // 更新加密构造器
    [self updateEncryptor];
}

- (NSDictionary *)encryptJSONObject:(id)obj {
    @try {
        if (!obj) {
            SALogDebug(@"Enable encryption but the input obj is invalid!");
            return nil;
        }

        if (![self hasSecretKey]) {
            SALogDebug(@"Enable encryption but the secret key is invalid!");
            return nil;
        }

        if (![self encryptAESKey]) {
            SALogDebug(@"Enable encryption but encrypt AES key is failed!");
            return nil;
        }

        // 使用 gzip 进行压缩
        NSData *jsonData = [SAJSONUtil JSONSerializeObject:obj];
        NSString *encodingString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSData *encodingData = [encodingString dataUsingEncoding:NSUTF8StringEncoding];
        NSData *zippedData = [SAGzipUtility gzipData:encodingData];

        // AES128 加密数据
        NSString *encryptedString = [self.dataEncryptor encryptObject:zippedData];
        if (![SAValidator isValidString:encryptedString]) {
            return nil;
        }

        // 封装加密的数据结构
        NSMutableDictionary *secretObj = [NSMutableDictionary dictionary];
        secretObj[@"pkv"] = @(self.secretKey.version);
        secretObj[@"ekey"] = self.encryptedAESKey;
        secretObj[@"payload"] = encryptedString;
        return [NSDictionary dictionaryWithDictionary:secretObj];
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
        return nil;
    }
}

#pragma mark - Private Methods

- (void)saveRequestSecretKey:(SASecretKey *)secretKey {
    if (!secretKey) {
        return;
    }

    void (^saveSecretKey)(SASecretKey *) = self.configOptions.saveSecretKey;
    if (saveSecretKey) {
        // 通过用户的回调保存公钥
        saveSecretKey(secretKey);

        [SAFileStore archiveWithFileName:kSAEncryptSecretKey value:nil];

        SALogDebug(@"Save secret key by saveSecretKey callback, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
    } else {
        // 存储到本地
        NSData *secretKeyData = [NSKeyedArchiver archivedDataWithRootObject:secretKey];
        [SAFileStore archiveWithFileName:kSAEncryptSecretKey value:secretKeyData];

        SALogDebug(@"Save secret key by localSecretKey, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
    }
}

- (SASecretKey *)loadCurrentSecretKey {
    SASecretKey *secretKey = nil;

    SASecretKey *(^loadSecretKey)(void) = self.configOptions.loadSecretKey;
    if (loadSecretKey) {
        // 通过用户的回调获取公钥
        secretKey = loadSecretKey();

        if (secretKey) {
            SALogDebug(@"Load secret key from loadSecretKey callback, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
        } else {
            SALogDebug(@"Load secret key from loadSecretKey callback failed!");
        }
    } else {
        // 通过本地获取公钥
        id secretKeyData = [SAFileStore unarchiveWithFileName:kSAEncryptSecretKey];
        if ([SAValidator isValidData:secretKeyData]) {
            secretKey = [NSKeyedUnarchiver unarchiveObjectWithData:secretKeyData];
        }

        if (secretKey) {
            SALogDebug(@"Load secret key from localSecretKey, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
        } else {
            SALogDebug(@"Load secret key from localSecretKey failed!");
        }
    }

    return secretKey;
}

- (void)updateEncryptor {
    @try {
        SASecretKey *secretKey = [self loadCurrentSecretKey];
        if (![SAValidator isValidString:secretKey.key]) {
            return;
        }

        // 返回的密钥与已有的密钥一样则不需要更新
        if ([self.secretKey.key isEqualToString:secretKey.key]) {
            return;
        }

        // 更新 AES 密钥加密器
        if ([secretKey.key hasPrefix:kSAEncryptECCPrefix]) {
            if (!NSClassFromString(kSAEncryptECCClassName)) {
                NSAssert(NO, @"\n您使用了 ECC 密钥，但是并没有集成 ECC 加密库。\n • 如果使用源码集成 ECC 加密库，请检查是否包含名为 SAECCEncrypt 的文件? \n • 如果使用 CocoaPods 集成 SDK，请修改 Podfile 文件并增加 ECC 模块，例如：pod 'SensorsAnalyticsEncrypt'。\n");
                return;
            }

            self.keyEncryptor = [[SAECCEncryptor alloc] initWithSecretKey:secretKey.key];
        } else {
            self.keyEncryptor = [[SARSAEncryptor alloc] initWithSecretKey:secretKey.key];
        }

        // 更新密钥
        self.secretKey = secretKey;

        // 更新原始的 AES 密钥
        self.originalAESKey = self.keyEncryptor.random16ByteData;

        // 更新加密后的 AES 密钥
        self.encryptedAESKey = [self.keyEncryptor encryptObject:self.originalAESKey];

        // 更新数据加密器
        self.dataEncryptor = [[SAAESEncryptor alloc] initWithSecretKey:self.originalAESKey];
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
}

- (BOOL)encryptAESKey {
    if (self.encryptedAESKey) {
        return YES;
    }

    self.encryptedAESKey = [self.keyEncryptor encryptObject:self.originalAESKey];

    return self.encryptedAESKey != nil;
}

@end
