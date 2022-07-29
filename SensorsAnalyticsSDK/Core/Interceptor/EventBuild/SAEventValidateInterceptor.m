//
// SAEventValidateInterceptor.m
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
