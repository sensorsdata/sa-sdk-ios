//
// SAAESCrypt.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/12/1.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAAESCrypt.h"
#import <CommonCrypto/CommonCryptor.h>

@interface SAAESCrypt ()

@property (nonatomic, copy, readwrite) NSData *key;

@end

@implementation SAAESCrypt

- (instancetype)initWithKey:(NSData *)key {
    self = [super init];
    if (self) {
        _key = key;
    }
    return self;
}

#pragma mark - Public Methods

- (NSData *)key {
    if (!_key) {
        _key = [SAAESCrypt randomKey];
    }
    return _key;
}

- (nullable NSString *)encryptData:(NSData *)obj {
    if (obj.length == 0) {
        return nil;
    }

    NSData *data = obj;
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);

    NSMutableData *iv = [NSMutableData dataWithLength:kCCBlockSizeAES128];
    int result = SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, iv.mutableBytes);
    if (result != errSecSuccess) {
        return nil;
    }

    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          [self.key bytes],
                                          kCCBlockSizeAES128,
                                          [iv bytes],
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        // 获得加密内容后，在内容前添加 16 位随机字节，增加数据复杂度
        NSData *encryptData = [NSData dataWithBytes:buffer length:numBytesEncrypted];
        NSMutableData *ivEncryptData = [NSMutableData dataWithData:iv];
        [ivEncryptData appendData:encryptData];

        free(buffer);

        NSData *base64EncodeData = [ivEncryptData base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
        NSString *encryptString = [[NSString alloc] initWithData:base64EncodeData encoding:NSUTF8StringEncoding];
        return encryptString;
    } else {
        free(buffer);
    }
    return nil;
}

- (nullable NSData *)decryptData:(NSData *)obj {
    if (obj.length == 0) {
        return nil;
    }

    // base64 解码
    NSData *encryptedData = [[NSData alloc] initWithBase64EncodedData:obj options:NSDataBase64DecodingIgnoreUnknownCharacters];

    NSUInteger dataLength = [encryptedData length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;

    NSMutableData *iv = [NSMutableData dataWithLength:kCCBlockSizeAES128];
    int result = SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, iv.mutableBytes);
    if (result != errSecSuccess) {
        return nil;
    }

    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          [self.key bytes],
                                          kCCBlockSizeAES128,
                                          [iv bytes],
                                          [encryptedData bytes],
                                          [encryptedData length],
                                          buffer,
                                          bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *result = [NSData dataWithBytes:buffer length:numBytesDecrypted];
        free(buffer);

        if (result.length <= 16) {
            return nil;
        }
        // 移除添加的 16 位随机字节
        NSRange range = NSMakeRange(16, result.length - 16);
        return [result subdataWithRange:range];

    } else {
        free(buffer);
    }
    return nil;
}

+ (NSData *)randomKey {
    // 默认使用 16 位长度随机字符串，RSA 和 ECC 保持一致
    NSUInteger length = 16;
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#$%&()*+,-./:;<=>?@[]^_{}|~";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex:arc4random_uniform((uint32_t)[letters length])]];
    }
    NSData *randomKey = [randomString dataUsingEncoding:NSUTF8StringEncoding];
    return randomKey;
}

@end
