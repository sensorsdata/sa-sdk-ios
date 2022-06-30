//
// SAQueryRecordInterceptor.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/16.
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

#import "SAQueryRecordInterceptor.h"
#import "SARepeatFlushInterceptor.h"

@interface SAConfigOptions ()

@property (nonatomic) SensorsAnalyticsDebugMode debugMode;

@end

@implementation SAQueryRecordInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {

    // 查询数据
    NSInteger queryCount = input.configOptions.debugMode != SensorsAnalyticsDebugOff ? 1 : 50;
    NSArray<SAEventRecord *> *records = [self.eventStore selectRecords:queryCount];
    if (records.count == 0) {
        input.state = SAFlowStateStop;
    } else {
        input.records = records;
    }

    return completion(input);
}

@end
