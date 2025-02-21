//
// SAEncryptor.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/23.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAlgorithmProtocol.h"

NSString * const kSAAlgorithmTypeAES = @"AES";
NSString * const kSAAlgorithmTypeRSA = @"RSA";
NSString * const kSAAlgorithmTypeECC = @"EC";
