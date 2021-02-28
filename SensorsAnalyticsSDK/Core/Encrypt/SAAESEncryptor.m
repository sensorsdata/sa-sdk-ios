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

@property (nonatomic, copy) NSData *secretKey;

@end

@implementation SAAESEncryptor

#pragma mark - Life Cycle

- (instancetype)initWithSecretKey:(id)secretKey {
    self = [super initWithSecretKey:secretKey];
    if (self) {
        [self configWithSecretKey:secretKey];
    }
    return self;
}

- (void)configWithSecretKey:(id)secretKey {
    if (![SAValidator isValidData:secretKey]) {
        return;
    }
    self.secretKey = secretKey;
}

#pragma mark - Public Methods

- (nullable NSString *)encryptObject:(NSData *)obj {
    if (![SAValidator isValidData:obj]) {
        SALogError(@"Enable AES encryption but the input obj is invalid!");
        return nil;
    }
    
    if (![SAValidator isValidData:self.secretKey]) {
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
                                          [self.secretKey bytes],
                                          kCCBlockSizeAES128,
                                          [ivData bytes],
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
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
