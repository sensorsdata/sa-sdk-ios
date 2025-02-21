//
// SAAESCrypt.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/12/14.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAAESCrypt : NSObject

@property (nonatomic, copy, readonly) NSData *key;

- (instancetype)initWithKey:(NSData *)key;

- (nullable NSString *)encryptData:(NSData *)data;
- (nullable NSData *)decryptData:(NSData *)obj;

+ (NSData *)randomKey;

@end

NS_ASSUME_NONNULL_END
