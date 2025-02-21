//
// SAAESEncryptor.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/12/12.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAESEncryptor.h"
#import <CommonCrypto/CommonCryptor.h>
#import "SAValidator.h"
#import "SALog.h"

@implementation SAAESEncryptor

#pragma mark - Public Methods

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

    return [super encryptData:obj];
}

@end
