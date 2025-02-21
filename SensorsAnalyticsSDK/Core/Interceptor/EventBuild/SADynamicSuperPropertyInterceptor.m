//
// SADynamicSuperPropertyInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SADynamicSuperPropertyInterceptor.h"
#import "SADynamicSuperPropertyPlugin.h"
#import "SAPropertyPluginManager.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"


@implementation SADynamicSuperPropertyInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {

    // 当前已经切换到了 serialQueue，说明外部已执行采集动态公共属性 block，不再重复执行
    dispatch_queue_t serialQueue = SensorsAnalyticsSDK.sdkInstance.serialQueue;
    if ( sensorsdata_is_same_queue(serialQueue)) {
        return completion(input);
    }

    SADynamicSuperPropertyPlugin *propertyPlugin = SADynamicSuperPropertyPlugin.sharedDynamicSuperPropertyPlugin;
    // 动态公共属性，需要在 serialQueue 外获取内容，在队列内添加
    [propertyPlugin buildDynamicSuperProperties];
    completion(input);
}

@end
