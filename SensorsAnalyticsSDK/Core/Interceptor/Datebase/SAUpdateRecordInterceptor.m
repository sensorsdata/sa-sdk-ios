//
// SAUpdateRecordInterceptor.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/17.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAUpdateRecordInterceptor.h"
#import "SAFileStorePlugin.h"
#import "SAEventStore.h"

@implementation SAUpdateRecordInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.records);

    // 更新状态
    // 获取查询到的数据的 id
    NSMutableArray *recordIDs = [NSMutableArray arrayWithCapacity:input.records.count];
    for (SAEventRecord *record in input.records) {
        [recordIDs addObject:record.recordID];
    }
    input.recordIDs = recordIDs;

    // 更新数据状态
    [self.eventStore updateRecords:recordIDs status:SAEventRecordStatusFlush];

    return completion(input);
}

@end
