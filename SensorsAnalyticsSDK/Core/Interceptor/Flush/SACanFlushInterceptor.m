//
// SACanFlushInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/8.
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
    SANetworkInfoPropertyPlugin *carrierPlugin = [[SANetworkInfoPropertyPlugin alloc] init];
    if (!([carrierPlugin currentNetworkTypeOptions] & input.configOptions.flushNetworkPolicy)) {
        input.state = SAFlowStateStop;
    }
    completion(input);
}

@end
