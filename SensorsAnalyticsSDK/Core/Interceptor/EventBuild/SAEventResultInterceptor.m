//
// SAEventResultInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/13.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAEventResultInterceptor.h"
#import "SAEventRecord.h"
#import "SAConstants+Private.h"
#import "SALog.h"
#import "SAModuleManager.h"

#if __has_include("SAAdvertisingConfig.h")
#import "SensorsAnalyticsSDK+DeepLink.h"
#import "SAAdvertisingConfig+Private.h"
#import "NSDictionary+SACopyProperties.h"
#import "SAFlowManager.h"
#endif

static NSString * const kSATEventTrackId = @"$sat_event_track_id";

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

    SAEventRecord *record = [[SAEventRecord alloc] initWithEvent:event type:@"POST"];
    record.isInstantEvent = input.eventObject.isInstantEvent;
    input.record = record;
#if __has_include("SAAdvertisingConfig.h")
    [self flushSATEventsWithInput:input];
#endif
    completion(input);
}

#if __has_include("SAAdvertisingConfig.h")
- (void)flushSATEventsWithInput:(SAFlowData *)input {
    NSDictionary *event = input.eventObject.jsonObject;
    NSString *eventName = event[@"event"];
    if (!eventName || ![input.configOptions.advertisingConfig.adsEvents containsObject:eventName]) {
        return;
    }
    NSString *uuid = [NSUUID UUID].UUIDString;
    input.eventObject.properties[kSATEventTrackId] = uuid;

    SAFlowData *newInput = [[SAFlowData alloc] init];
    SAEventRecord *record = [[SAEventRecord alloc] initWithEvent:[event sensorsdata_deepCopy] type:@"POST"];
    newInput.records = @[record];
    newInput.isAdsEvent = YES;
    [SAFlowManager.sharedInstance startWithFlowID:kSATFlushFlowId input:newInput completion:nil];
}
#endif

@end
