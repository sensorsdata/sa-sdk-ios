//
// SAInsertRecordInterceptor.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/17.
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

#import "SAInsertRecordInterceptor.h"

@interface SAConfigOptions ()

@property (nonatomic) SensorsAnalyticsDebugMode debugMode;

@end


@implementation SAInsertRecordInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.record);
    
    [self.eventStore insertRecord:input.record];

    // 不满足 flush 条件，流程结束
    // 判断本地数据库中未上传的数量
    if (!input.eventObject.isSignUp &&
        [self.eventStore recordCountWithStatus:SAEventRecordStatusNone] <= input.configOptions.flushBulkSize &&
        input.configOptions.debugMode == SensorsAnalyticsDebugOff) {
        input.state = SAFlowStateStop;
    }
    return completion(input);
}

@end
