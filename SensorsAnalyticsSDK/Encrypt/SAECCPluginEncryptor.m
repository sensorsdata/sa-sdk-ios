//
// SAECCPluginEncryptor.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/14.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAECCPluginEncryptor.h"
#import "SAAESEncryptor.h"
#import "SAECCEncryptor.h"

@interface SAECCPluginEncryptor ()

@property (nonatomic, strong) SAAESEncryptor *aesEncryptor;
@property (nonatomic, strong) SAECCEncryptor *eccEncryptor;

@end

@implementation SAECCPluginEncryptor

+ (BOOL)isAvaliable {
    return NSClassFromString(kSAEncryptECCClassName) != nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _aesEncryptor = [[SAAESEncryptor alloc] init];
        _eccEncryptor = [[SAECCEncryptor alloc] init];
    }
    return self;
}

- (NSString *)symmetricEncryptType {
    return [_aesEncryptor algorithm];
}

- (NSString *)asymmetricEncryptType {
    return [_eccEncryptor algorithm];
}

- (NSString *)encryptEvent:(NSData *)event {
    return [_aesEncryptor encryptData:event];
}

- (NSString *)encryptSymmetricKeyWithPublicKey:(NSString *)publicKey {
    if (![_eccEncryptor.key isEqualToString:publicKey]) {
        _eccEncryptor.key = publicKey;
    }
    return [_eccEncryptor encryptData:_aesEncryptor.key];
}

@end
