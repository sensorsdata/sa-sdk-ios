//
// SAECCEncryptor.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/12/2.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAAlgorithmProtocol.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSAEncryptECCClassName;
extern NSString * const kSAEncryptECCPrefix;

@interface SAECCEncryptor : NSObject <SAAlgorithmProtocol>

@property (nonatomic, copy) NSString *key;

@end

NS_ASSUME_NONNULL_END
