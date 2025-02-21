//
// SASerialQueueInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
