//
// SAAdsEncryptInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/8/15.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAdsEncryptInterceptor.h"
#import "SensorsAnalyticsSDK+DeepLink.h"
#import "SAModuleManager.h"
#import "SAEventRecord.h"
#import "SAAdvertisingConfig+Private.h"

@implementation SAAdsEncryptInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);

    if (input.records.count < 1) {
        input.state = SAFlowStateStop;
        completion(input);
        return;
    }

    // 开启埋点加密
    if (input.configOptions.advertisingConfig.adsSecretKey) {
        SAEventRecord *record = input.records.firstObject;
        NSDictionary *obj = [SAModuleManager.sharedInstance encryptEvent:record.event withKey:input.configOptions.advertisingConfig.adsSecretKey];
        [record setSecretObject:obj];
        input.records = @[record];
        return completion(input);
    }
    completion(input);
}

@end
