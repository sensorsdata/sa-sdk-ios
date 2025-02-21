//
// SAConfigOptions+Encrypt.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/6/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAConfigOptions+Encrypt.h"
#import "SAConfigOptions+EncryptPrivate.h"
#import "SAEncryptProtocol.h"

@interface SAConfigOptions ()

@property (atomic, strong, readwrite) NSMutableArray *encryptors;
@property (nonatomic, assign) BOOL enableEncrypt;
@property (nonatomic, assign) BOOL enableTransportEncrypt;
@property (nonatomic, copy) void (^saveSecretKey)(SASecretKey * _Nonnull secretKey);
@property (nonatomic, copy) SASecretKey * _Nonnull (^loadSecretKey)(void);
@property (nonatomic, strong) id<SAEventEncryptProtocol> eventEncryptor;

@end

@implementation SAConfigOptions (Encrypt)

- (void)registerEncryptor:(id<SAEncryptProtocol>)encryptor {
    if (![self isValidEncryptor:encryptor]) {
        NSString *format = @"\n You used a custom encryption plugin [ %@ ], but no encryption protocol related methods are implemented. Please correctly implement the related functions of the custom encryption plugin before running the project. \n";
        NSString *message = [NSString stringWithFormat:format, NSStringFromClass(encryptor.class)];
        NSAssert(NO, message);
        return;
    }
    if (!self.encryptors) {
        self.encryptors = [[NSMutableArray alloc] init];
    }
    [self.encryptors addObject:encryptor];
}

- (BOOL)isValidEncryptor:(id<SAEncryptProtocol>)encryptor {
    return ([encryptor respondsToSelector:@selector(symmetricEncryptType)] &&
            [encryptor respondsToSelector:@selector(asymmetricEncryptType)] &&
            [encryptor respondsToSelector:@selector(encryptEvent:)] &&
            [encryptor respondsToSelector:@selector(encryptSymmetricKeyWithPublicKey:)]);
}

- (void)registerEventEncryptor:(id<SAEventEncryptProtocol>)encryptor {
    if([encryptor respondsToSelector:@selector(encryptEventRecord:)] && [encryptor respondsToSelector:@selector(decryptEventRecord:)]) {
        self.eventEncryptor = encryptor;
    }
}

@end
