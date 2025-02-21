//
// SADeleteRecordInterceptor.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/17.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
