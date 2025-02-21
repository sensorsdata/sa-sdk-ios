//
// SAAESEncryptor.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/12/12.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAAlgorithmProtocol.h"
#import "SAAESCrypt.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAESEncryptor : SAAESCrypt <SAAlgorithmProtocol>

@end

NS_ASSUME_NONNULL_END
