//
// SASAFlushJSONInterceptor+Encrypt.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/4/7.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAFlushJSONInterceptor+Encrypt.h"
#import "SAEventRecord.h"
#import "SAEncryptManager.h"
#import "SAConfigOptions+EncryptPrivate.h"
#import "SAJSONUtil.h"
#import "SAConstants+Private.h"

@interface SAConfigOptions ()

@property (nonatomic, assign) BOOL enableEncrypt;

@end

@implementation SAFlushJSONInterceptor (Encrypt)

- (NSString *)sensorsdata_buildJSONStringWithRecords:(NSArray<SAEventRecord *> *)records {
    BOOL isEncrypted = [SAEncryptManager defaultManager].configOptions.enableEncrypt && records.firstObject.isEncrypted;
    if (isEncrypted) {
        return [self buildEncryptJSONStringWithRecords:records];
    }
    BOOL enableFlushEncrypt = [SAEncryptManager defaultManager].configOptions.enableFlushEncrypt;
    if (!enableFlushEncrypt) {
        return [self sensorsdata_buildJSONStringWithRecords:records];
    }
    if (records.firstObject.isEncrypted) {
        return [self buildEncryptJSONStringWithRecords:records];
    }
    return [self buildFlushEncryptJSONStringWithRecords:records];
}

- (NSString *)buildEncryptJSONStringWithRecords:(NSArray<SAEventRecord *> *)records {
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
    return [self sensorsdata_buildJSONStringWithRecords:encryptRecords];
}

- (NSString *)buildFlushEncryptJSONStringWithRecords:(NSArray<SAEventRecord *> *)records {
    NSMutableArray *events = [NSMutableArray array];
    for (SAEventRecord *record in records) {
        [events addObject:record.event];
    }
    NSDictionary *encryptEvents = [[SAEncryptManager defaultManager] encryptJSONObject:events];
    if (!encryptEvents) {
        return nil;
    }
    NSMutableDictionary *tempEncryptEvents = [NSMutableDictionary dictionary];
    tempEncryptEvents[kSAEncryptRecordKeyPayloads] = encryptEvents[kSAEncryptRecordKeyPayload];
    tempEncryptEvents[kSAEncryptRecordKeyEKey] = encryptEvents[kSAEncryptRecordKeyEKey];
    tempEncryptEvents[kSAEncryptRecordKeyPKV] = encryptEvents[kSAEncryptRecordKeyPKV];
    UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
    tempEncryptEvents[kSAEncryptRecordKeyFlushTime] = @(time);
    return [SAJSONUtil stringWithJSONObject:@[tempEncryptEvents]];
}

@end
