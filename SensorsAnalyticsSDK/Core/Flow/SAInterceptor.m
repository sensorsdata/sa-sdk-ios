//
// SAInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAInterceptor.h"

@implementation SAInterceptor

+ (instancetype)interceptorWithParam:(NSDictionary * _Nullable)param {
    return [[self alloc] init];
}

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSAssert(NO, @"The sub interceptor must implement this method.");
    completion(input);
}

@end
