//
// SAInsertRecordInterceptor.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/17.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAInsertRecordInterceptor.h"

@interface SAConfigOptions ()

@property (nonatomic) SensorsAnalyticsDebugMode debugMode;

@end


@implementation SAInsertRecordInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.record);
    
    [self.eventStore insertRecord:input.record];

    // 不满足 flush 条件，流程结束
    // 判断本地数据库中未上传的数量
    if (!input.eventObject.isSignUp &&
        [self.eventStore recordCountWithStatus:SAEventRecordStatusNone] <= input.configOptions.flushBulkSize &&
        input.configOptions.debugMode == SensorsAnalyticsDebugOff && !input.isInstantEvent) {
        input.state = SAFlowStateStop;
    }
    return completion(input);
}

@end
