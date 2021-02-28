//
// SAECCEncryptor.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/12/2.
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

#import "SAECCEncryptor.h"
#import "SAValidator.h"
#import "SALog.h"

NSString * const kSAEncryptECCPrefix = @"EC:";
NSString * const kSAEncryptECCClassName = @"SACryptoppECC";

typedef NSString* (*SAEEncryptImplementation)(Class, SEL, NSString *, NSString *);

@interface SAECCEncryptor ()

/// 移除 EC: 前缀之后真正的公钥
@property (nonatomic, copy) NSString *publicKey;

@end

@implementation SAECCEncryptor

#pragma mark - Life Cycle

- (instancetype)initWithSecretKey:(NSString *)secretKey {
    self = [super initWithSecretKey:secretKey];
    if (self) {
        [self configWithSecretKey:secretKey];
    }
    return self;
}

- (void)configWithSecretKey:(id)secretKey {
    if (![SAValidator isValidString:secretKey]) {
        SALogError(@"Enable ECC encryption but the secret key is invalid!");
        return;
    }

    if (![secretKey hasPrefix:kSAEncryptECCPrefix]) {
        SALogError(@"Enable ECC encryption but the secret key is not ECC key!");
        return;
    }

    self.publicKey = [secretKey substringFromIndex:[kSAEncryptECCPrefix length]];
}

#pragma mark - Public Methods

- (nullable NSString *)encryptObject:(NSData *)obj {
    if (![SAValidator isValidData:obj]) {
        SALogError(@"Enable ECC encryption but the input obj is invalid!");
        return nil;
    }
    
    if (![SAValidator isValidString:self.publicKey]) {
        SALogError(@"Enable ECC encryption but the public key is invalid!");
        return nil;
    }
    
    Class class = NSClassFromString(kSAEncryptECCClassName);
    SEL selector = NSSelectorFromString(@"encrypt:withPublicKey:");
    IMP methodIMP = [class methodForSelector:selector];
    if (methodIMP) {
        NSString *string = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
        return ((SAEEncryptImplementation)methodIMP)(class, selector, string, self.publicKey);
    }
    
    return nil;
}

- (NSData *)random16ByteData {
    NSUInteger length = 16;
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#$%&()*+,-./:;<=>?@[]^_{}|~";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex:arc4random_uniform((uint32_t)[letters length])]];
    }
    return [randomString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
