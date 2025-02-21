//
// SAECCPluginEncryptor.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/14.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAEncryptProtocol.h"
#import "SAECCEncryptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAECCPluginEncryptor : NSObject <SAEncryptProtocol>

+ (BOOL)isAvaliable;

@end

NS_ASSUME_NONNULL_END
