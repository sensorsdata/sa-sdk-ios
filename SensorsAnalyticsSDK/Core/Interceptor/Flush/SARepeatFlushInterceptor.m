//
// SARepeatFlushInterceptor.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/31.
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

#import "SARepeatFlushInterceptor.h"
#import "SAFlowManager.h"

static NSInteger const kSAFlushMaxRepeatCount = 100;

@interface SARepeatFlushInterceptor ()
@end

@implementation SARepeatFlushInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    if (input.repeatCount >= kSAFlushMaxRepeatCount) {
        // 到达最大次数，暂停上传
        input.state = SAFlowStateStop;
        return completion(input);
    }

    SAFlowData *inputData = [[SAFlowData alloc] init];
    inputData.cookie = input.cookie;
    inputData.repeatCount = input.repeatCount + 1;
    // 当前已处于 serialQueue，不必再切队列
    [SAFlowManager.sharedInstance startWithFlowID:kSAFlushFlowId input:inputData completion:^(SAFlowData * _Nonnull output) {
        completion(output);
    }];
}

@end
