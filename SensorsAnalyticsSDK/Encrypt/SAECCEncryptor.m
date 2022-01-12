//
// SAECCEncryptor.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/12/2.
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

#import "SAECCEncryptor.h"
#import "SAValidator.h"
#import "SALog.h"

NSString * const kSAEncryptECCClassName = @"SACryptoppECC";
NSString * const kSAEncryptECCPrefix = @"EC:";

typedef NSString* (*SAEEncryptImplementation)(Class, SEL, NSString *, NSString *);

@implementation SAECCEncryptor

- (void)setKey:(NSString *)key {
    if (![SAValidator isValidString:key]) {
        SALogError(@"Enable ECC encryption but the secret key is invalid!");
        return;
    }

    // 兼容老版本逻辑，当前缀包含 EC: 时删除前缀信息
    if ([key hasPrefix:kSAEncryptECCPrefix]) {
        _key = [key substringFromIndex:[kSAEncryptECCPrefix length]];
    } else {
        _key = key;
    }
}

#pragma mark - Public Methods
- (NSString *)encryptData:(NSData *)obj {
    if (![SAValidator isValidData:obj]) {
        SALogError(@"Enable ECC encryption but the input obj is invalid!");
        return nil;
    }

    // 去除非对称秘钥公钥中的前缀内容，返回实际的非对称秘钥公钥内容
    NSString *asymmetricKey = self.key;
    if (![SAValidator isValidString:asymmetricKey]) {
        SALogError(@"Enable ECC encryption but the public key is invalid!");
        return nil;
    }
    
    Class class = NSClassFromString(kSAEncryptECCClassName);
    SEL selector = NSSelectorFromString(@"encrypt:withPublicKey:");
    IMP methodIMP = [class methodForSelector:selector];
    if (methodIMP) {
        NSString *string = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
        return ((SAEEncryptImplementation)methodIMP)(class, selector, string, asymmetricKey);
    }
    
    return nil;
}

- (NSString *)algorithm {
    return kSAAlgorithmTypeECC;
}

@end
