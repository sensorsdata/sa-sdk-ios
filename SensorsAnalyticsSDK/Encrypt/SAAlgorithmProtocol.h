//
// SAEncryptor.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/23.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSAAlgorithmTypeAES;
extern NSString * const kSAAlgorithmTypeRSA;
extern NSString * const kSAAlgorithmTypeECC;

@protocol SAAlgorithmProtocol <NSObject>

- (nullable NSString *)encryptData:(NSData *)data;
- (NSString *)algorithm;

@end

NS_ASSUME_NONNULL_END
