//
// SAFlushJSONInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/11.
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

#import "SAFlushJSONInterceptor.h"
#import "SAEventRecord.h"

#pragma mark -

@implementation SAFlushJSONInterceptor

// 1. 先完成这一系列 Json 字符串的拼接
- (NSString *)buildJSONStringWithFlowData:(SAFlowData *)flowData {
    NSArray <SAEventRecord *> *records = flowData.records;
    NSMutableArray *contents = [NSMutableArray arrayWithCapacity:records.count];
    for (SAEventRecord *record in records) {
        NSString *flushContent = [record flushContent];
        if (flushContent) {
            [contents addObject:flushContent];
        }
    }
    flowData.gzipCode = SAFlushGzipCodePlainText;
    return [NSString stringWithFormat:@"[%@]", [contents componentsJoinedByString:@","]];
}

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    NSParameterAssert(input.records.count > 0);
    input.json = [self buildJSONStringWithFlowData:input];
    if (![SAValidator isValidString:input.json]) {
        input.state = SAFlowStateStop;
    }
    completion(input);
}

@end
