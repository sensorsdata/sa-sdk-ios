//
// SAConfigOptions+Encrypt+Private.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/4/6.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//


#import "SAConfigOptions.h"
#import "SAEncryptProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (SAEncryptPrivate)

/// enable encrypt bulk events when flush
@property (nonatomic, assign) BOOL enableFlushEncrypt;
- (void)registerEventEncryptor:(id<SAEventEncryptProtocol>)encryptor API_UNAVAILABLE(macos);

@end

NS_ASSUME_NONNULL_END
