//
// SAAdsEncryptInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/8/15.
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
