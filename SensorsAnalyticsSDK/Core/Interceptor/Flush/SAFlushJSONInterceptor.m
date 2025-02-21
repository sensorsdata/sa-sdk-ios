//
// SAFlushJSONInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
