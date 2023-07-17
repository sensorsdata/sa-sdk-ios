//
// SAAESEventEncryptor.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/6/26.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAAESEventEncryptor.h"
#import "SAAESCrypt.h"
#import "SAFileStorePlugin.h"

static NSString * const kSAAESEventEncryptKey = @"SAEventEncrypt.AES";

@interface SAAESEventEncryptor ()

@property (nonatomic, strong) SAAESCrypt *aesEncryptor;
@property (nonatomic, copy) NSData *key;

@end

@implementation SAAESEventEncryptor

- (NSString *)encryptEventRecord:(NSData *)eventRecord {
    return [self.aesEncryptor encryptData:eventRecord];
}

- (NSData *)decryptEventRecord:(NSString *)eventRecord {
    return [self.aesEncryptor decryptData:[eventRecord dataUsingEncoding:NSUTF8StringEncoding]];
}

- (SAAESCrypt *)aesEncryptor {
    if (!_aesEncryptor) {
        [self loadEncryptKey];
        _aesEncryptor = [[SAAESCrypt alloc] initWithKey:self.key];
    }
    return _aesEncryptor;
}

- (void)loadEncryptKey {
    SAFileStorePlugin *fileStore = [[SAFileStorePlugin alloc] init];
    NSData *base64EncodedKey = [fileStore objectForKey:kSAAESEventEncryptKey];
    NSData *key = nil;
    if (base64EncodedKey) {
        key = [[NSData alloc] initWithBase64EncodedData:base64EncodedKey options:0];
    }
    if (!key) {
        key = [SAAESCrypt randomKey];
        NSData *keyData = [key base64EncodedDataWithOptions:0];
        [fileStore setObject:keyData forKey:kSAAESEventEncryptKey];
    }
    _key = key;
}

@end
