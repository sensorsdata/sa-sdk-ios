//
// SAEventValidateInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAEventValidateInterceptor.h"
#import "SAModuleManager.h"
#import "SAPropertyValidator.h"

@implementation SAEventValidateInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);

    // 事件名校验
    NSError *error = nil;
    [input.eventObject validateEventWithError:&error];
    if (error) {
        [SAModuleManager.sharedInstance showDebugModeWarning:error.localizedDescription];
    }
    input.message = error.localizedDescription;

    // 传入 properties 校验
    input.properties = [SAPropertyValidator validProperties:input.properties];
    completion(input);
}

@end
