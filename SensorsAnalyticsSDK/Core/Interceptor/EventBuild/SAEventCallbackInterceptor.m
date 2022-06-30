//
// SAEventCallbackInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAEventCallbackInterceptor.h"
#import "SensorsAnalyticsSDK.h"
#import "SALog.h"

static NSString * const kSAEventCallbackKey = @"event_callback";

@interface SensorsAnalyticsSDK ()

@property (nonatomic, copy) SAEventCallback trackEventCallback;

@end

#pragma mark -

@interface SAEventCallbackInterceptor ()

@property (nonatomic, copy) SAEventCallback callback;

@end

@implementation SAEventCallbackInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);

    NSString *eventName = input.eventObject.event;
    SAEventCallback callback = [SensorsAnalyticsSDK sharedInstance].trackEventCallback;
    if (!callback || !eventName) {
        return completion(input);
    }

    BOOL willEnqueue = callback(eventName, input.eventObject.properties);
    if (!willEnqueue) {
        SALogDebug(@"\n【track event】: %@ can not insert database.", eventName);

        input.state = SAFlowStateError;
        return completion(input);
    }

    // 校验 properties
    input.eventObject.properties = [SAPropertyValidator validProperties:input.eventObject.properties];

    completion(input);
}

@end
