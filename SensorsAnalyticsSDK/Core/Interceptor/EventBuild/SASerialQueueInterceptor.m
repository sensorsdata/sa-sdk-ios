//
// SASerialQueueInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
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

#import "SASerialQueueInterceptor.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"

NSString * const kSASerialQueueSync = @"sync";

@interface SASerialQueueInterceptor ()

@property (nonatomic, assign) BOOL isSync;

@end

@implementation SASerialQueueInterceptor

+ (instancetype)interceptorWithParam:(NSDictionary *)param {
    SASerialQueueInterceptor *interceptor = [[SASerialQueueInterceptor alloc] init];
    if ([param[kSASerialQueueSync] isKindOfClass:NSNumber.class]) {
        interceptor.isSync = [param[kSASerialQueueSync] boolValue];
    }
    return interceptor;
}

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    dispatch_queue_t serialQueue = SensorsAnalyticsSDK.sdkInstance.serialQueue;
    if (sensorsdata_is_same_queue(serialQueue)) {
        return completion(input);
    }

    if (self.isSync) {
        dispatch_sync(serialQueue, ^{
            completion(input);
        });
    } else {
        dispatch_async(serialQueue, ^{
            completion(input);
        });
    }
}

@end
