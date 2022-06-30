//
// SADeleteRecordInterceptor.m
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

#import "SADeleteRecordInterceptor.h"

@implementation SADeleteRecordInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    // 从库中读出，准备上传时设置 recordIDs
    if (!input.recordIDs) {
        return completion(input);
    }

    // 上传完成
    if (input.flushSuccess) {
        [self.eventStore deleteRecords:input.recordIDs];

        if (self.eventStore.count == 0) {
            input.state = SAFlowStateStop;
        }
    } else {
        [self.eventStore updateRecords:input.recordIDs status:SAEventRecordStatusNone];
        input.state = SAFlowStateStop;
    }
    return completion(input);
}

@end
