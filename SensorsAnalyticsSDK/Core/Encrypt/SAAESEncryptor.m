//
// SAAESEncryptor.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/12/12.
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

#import "SAAESEncryptor.h"
#import <CommonCrypto/CommonCryptor.h>
#import "SAValidator.h"
#import "SALog.h"

@interface SAAESEncryptor ()

@property (nonatomic, copy, readwrite) NSData *key;

@end

@implementation SAAESEncryptor
#pragma mark - Public Methods

- (NSData *)key {
    if (!_key) {
        // 默认使用 16 位长度随机字符串，RSA 和 ECC 保持一致
        NSUInteger length = 16;
        NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#$%&()*+,-./:;<=>?@[]^_{}|~";
        NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
        for (NSUInteger i = 0; i < length; i++) {
            [randomString appendFormat: @"%C", [letters characterAtIndex:arc4random_uniform((uint32_t)[letters length])]];
        }
        _key = [randomString dataUsingEncoding:NSUTF8StringEncoding];
    }
    return _key;
}

- (NSString *)algorithm {
    return kSAAlgorithmTypeAES;
}

- (nullable NSString *)encryptData:(NSData *)obj {
    if (![SAValidator isValidData:obj]) {
        SALogError(@"Enable AES encryption but the input obj is invalid!");
        return nil;
    }

    if (![SAValidator isValidData:self.key]) {
        SALogError(@"Enable AES encryption but the secret key data is invalid!");
        return nil;
    }
    
    NSData *data = obj;
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    unsigned char buf[16];
    arc4random_buf(buf, sizeof(buf));
    NSData *ivData = [NSData dataWithBytes:buf length:sizeof(buf)];
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          [self.key bytes],
                                          kCCBlockSizeAES128,
                                          [ivData bytes],
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        // 获得加密内容后，在内容前添加 16 位随机字节，增加数据复杂度
        NSData *encryptData = [NSData dataWithBytes:buffer length:numBytesEncrypted];
        NSMutableData *ivEncryptData = [NSMutableData dataWithData:ivData];
        [ivEncryptData appendData:encryptData];
        
        free(buffer);
        
        NSData *base64EncodeData = [ivEncryptData base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
        NSString *encryptString = [[NSString alloc] initWithData:base64EncodeData encoding:NSUTF8StringEncoding];
        return encryptString;
    } else {
        free(buffer);
        SALogError(@"AES encrypt data failed, with error Code: %d",(int)cryptStatus);
    }
    return nil;
}

@end
