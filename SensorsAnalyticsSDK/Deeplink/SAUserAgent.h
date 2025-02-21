//
// SAUserAgent.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/8/19.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAUserAgent : NSObject

+ (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion;

@end

NS_ASSUME_NONNULL_END
