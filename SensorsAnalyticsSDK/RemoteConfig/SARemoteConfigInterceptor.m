//
// SARemoteConfigInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SARemoteConfigInterceptor.h"
#import "SAModuleManager.h"

@implementation SARemoteConfigInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);

    // 线上极端情况下，切换到异步 serialQueue 后，eventObject 可能被释放
    if(!input.eventObject || ![input.eventObject isKindOfClass:SABaseEventObject.class]) {
        input.state = SAFlowStateError;
        input.message = @"A memory problem has occurred, eventObject may be freed. End the track flow";
    }
    
    if ([SAModuleManager.sharedInstance isIgnoreEventObject:input.eventObject]) {
        input.state = SAFlowStateStop;
    }
    completion(input);
}

@end
