//
// NSDictionary+CopyProperties.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/10/13.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (SACopyProperties)

//use to safe copy event properties
- (NSDictionary *)sensorsdata_deepCopy;

@end

NS_ASSUME_NONNULL_END
