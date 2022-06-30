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
#import "SAJSONUtil.h"
#import "SAEventRecord.h"

@interface SAConfigOptions ()

@property (nonatomic, assign) BOOL enableEncrypt;

@end

#pragma mark -

@implementation SAFlushJSONInterceptor

// 1. 先完成这一系列 Json 字符串的拼接
- (NSString *)buildFlushJSONStringWithEventRecords:(NSArray<SAEventRecord *> *)records {
    NSMutableArray *contents = [NSMutableArray arrayWithCapacity:records.count];
    for (SAEventRecord *record in records) {
        NSString *flushContent = [record flushContent];
        if (flushContent) {
            [contents addObject:flushContent];
        }
    }
    return [NSString stringWithFormat:@"[%@]", [contents componentsJoinedByString:@","]];
}

- (NSString *)buildFlushEncryptJSONStringWithEventRecords:(NSArray<SAEventRecord *> *)records {
    // 初始化用于保存合并后的事件数据
    NSMutableArray *encryptRecords = [NSMutableArray arrayWithCapacity:records.count];
    // 用于保存当前存在的所有 ekey
    NSMutableArray *ekeys = [NSMutableArray arrayWithCapacity:records.count];
    for (SAEventRecord *record in records) {
        NSInteger index = [ekeys indexOfObject:record.ekey];
        if (index == NSNotFound) {
            [record removePayload];
            [encryptRecords addObject:record];

            [ekeys addObject:record.ekey];
        } else {
            [encryptRecords[index] mergeSameEKeyRecord:record];
        }
    }
    return [self buildFlushJSONStringWithEventRecords:encryptRecords];
}

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    NSParameterAssert(input.records.count > 0);

    // 判断是否加密数据
    BOOL isEncrypted = input.configOptions.enableEncrypt && input.records.firstObject.isEncrypted;
    input.json = isEncrypted ? [self buildFlushEncryptJSONStringWithEventRecords:input.records] : [self buildFlushJSONStringWithEventRecords:input.records];
    completion(input);
}

@end
