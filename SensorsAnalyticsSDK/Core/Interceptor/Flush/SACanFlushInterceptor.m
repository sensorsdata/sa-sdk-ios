//
// SACanFlushInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SACanFlushInterceptor.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SANetworkInfoPropertyPlugin.h"

@implementation SACanFlushInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    
    if (input.configOptions.serverURL.length == 0) {
        input.state = SAFlowStateStop;
    }
    
    // 判断当前网络类型是否符合同步数据的网络策略
    SANetworkInfoPropertyPlugin *networkPlugin = [[SANetworkInfoPropertyPlugin alloc] init];
    if (!([networkPlugin currentNetworkTypeOptions] & input.configOptions.flushNetworkPolicy)) {
        input.state = SAFlowStateStop;
    }
    completion(input);
}

@end
