//
// SALimitKeyManager.h
// SensorsAnalyticsSDK
//
// Created by MC on 2022/10/20.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface SALimitKeyManager : NSObject

+ (void)registerLimitKeys:(NSDictionary<SALimitKey, NSString *> *)keys;

+ (NSString *)idfa;
+ (NSString *)idfv;

@end

NS_ASSUME_NONNULL_END
