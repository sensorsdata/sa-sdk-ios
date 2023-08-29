//
// SARemoteConfigInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
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
