//
// SARepeatFlushInterceptor.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/31.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SARepeatFlushInterceptor.h"
#import "SAFlowManager.h"

static NSInteger const kSAFlushMaxRepeatCount = 40;

@interface SARepeatFlushInterceptor ()
@end

@implementation SARepeatFlushInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    if (input.repeatCount >= kSAFlushMaxRepeatCount) {
        // 到达最大次数，暂停上传
        input.state = SAFlowStateStop;
        return completion(input);
    }

    SAFlowData *inputData = [[SAFlowData alloc] init];
    inputData.cookie = input.cookie;
    inputData.repeatCount = input.repeatCount + 1;
    inputData.isInstantEvent = input.isInstantEvent;
    // 当前已处于 serialQueue，不必再切队列
    [SAFlowManager.sharedInstance startWithFlowID:kSAFlushFlowId input:inputData completion:^(SAFlowData * _Nonnull output) {
        completion(output);
    }];
}

@end
