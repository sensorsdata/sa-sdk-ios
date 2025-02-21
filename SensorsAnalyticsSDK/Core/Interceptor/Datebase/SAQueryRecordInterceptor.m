//
// SAQueryRecordInterceptor.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
    NSArray<SAEventRecord *> *records = [self.eventStore selectRecords:queryCount isInstantEvent:input.isInstantEvent];
    if (records.count == 0) {
        input.state = SAFlowStateStop;
    } else {
        input.records = records;
    }

    return completion(input);
}

@end
