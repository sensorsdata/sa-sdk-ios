//
// SAAdvertisingConfig.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/8/16.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SASecretKey.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAdvertisingConfig : NSObject <NSCopying>

- (instancetype)initWithServerUrl:(NSString *)serverUrl events:(NSArray<NSString *>*)events secretKey:(nullable SASecretKey *)key;

/// enable remarketing or not, default is NO
@property (nonatomic, assign) BOOL enableRemarketing;

/// url that wakeup app, pass the url to SDK in case that you delay init SDK
@property (nonatomic, copy) NSString *wakeupUrl;

@end

NS_ASSUME_NONNULL_END
