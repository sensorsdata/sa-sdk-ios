//
// SAEventResultInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/13.
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

#import "SAEventResultInterceptor.h"
#import "SAEventRecord.h"
#import "SAConstants+Private.h"
#import "SALog.h"

@implementation SAEventResultInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);
    
    NSMutableDictionary *event = input.eventObject.jsonObject;

    // H5 打通事件
    if (input.eventObject.hybridH5) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_EVENT_H5_NOTIFICATION object:nil userInfo:event];

        // 移除埋点校验中用到的事件名
        [input.eventObject.properties removeObjectForKey:kSAWebVisualEventName];

        event = input.eventObject.jsonObject;
        SALogDebug(@"\n【track event from H5】:\n%@", event);

    } else {
        // track 事件通知
        [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_EVENT_NOTIFICATION object:nil userInfo:event];
        SALogDebug(@"\n【track event】:\n%@", event);
    }

    input.record = [[SAEventRecord alloc] initWithEvent:event type:@"POST"];
    completion(input);
}

@end
