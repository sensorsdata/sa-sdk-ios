//
// SAEncryptInterceptor.m
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

#import "SAEncryptInterceptor.h"
#import "SAModuleManager.h"
#import "SAEventRecord.h"
#import "SAConfigOptions+Encrypt.h"
#import "SAEncryptManager.h"

#pragma mark -

@implementation SAEncryptInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    NSParameterAssert(input.record || input.records);

    if (input.records) { // 读取数据库后，进行数据合并。如果开启加密，会尝试加密
        input.records = [self encryptEventRecords:input.records];
        return completion(input);
    }

    // 未开启加密
    if (!input.configOptions.enableEncrypt) {
        return completion(input);
    }

    // 入库前，单条数据加密
    if (input.record) {
        NSDictionary *obj = [SAModuleManager.sharedInstance encryptJSONObject:input.record.event];
        [input.record setSecretObject:obj];
    }

    completion(input);
}

/// 筛选加密数据，并对未加密的数据尝试加密
///
/// 即使未开启加密，也需要进行筛选，可能因为后期修改加密开关，导致本地同时存在明文和密文数据
///
/// @param records 数据
- (NSArray<SAEventRecord *> *)encryptEventRecords:(NSArray<SAEventRecord *> *)records {
    NSMutableArray *encryptRecords = [NSMutableArray arrayWithCapacity:records.count];
    for (SAEventRecord *record in records) {
        if (record.isEncrypted) {
            [encryptRecords addObject:record];
            continue;
        }
        if (!([SAEncryptManager defaultManager].configOptions.enableEncrypt)) {
            continue;
        }
        // 缓存数据未加密，再加密
        NSDictionary *obj = [SAModuleManager.sharedInstance encryptJSONObject:record.event];
        if (obj) {
            [record setSecretObject:obj];
            [encryptRecords addObject:record];
        }
    }
    return encryptRecords.count == 0 ? records : encryptRecords;
}

@end
