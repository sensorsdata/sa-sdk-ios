//
// SACorrectUserIdInterceptor.m
// SensorsABTest
//
// Created by  储强盛 on 2022/6/13.
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

#import "SACorrectUserIdInterceptor.h"
#import "SAValidator.h"

#pragma mark userId
// A/B Testing 触发 $ABTestTrigge 事件修正属性
static NSString *const kSABLoginId = @"sab_loginId";
static NSString *const kSABDistinctId = @"sab_distinctId";
static NSString *const kSABAnonymousId = @"sab_anonymousId";
static NSString *const kSABTriggerEventName = @"$ABTestTrigger";


// SF 触发 $PlanPopupDisplay 事件修正属性
static NSString * const kSFDistinctId = @"sf_distinctId";
static NSString * const kSFLoginId = @"sf_loginId";
static NSString * const kSFAnonymousId = @"sf_anonymousId";
static NSString * const SFPlanPopupDisplayEventName = @"$PlanPopupDisplay";


@implementation SACorrectUserIdInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);
    if (!input.properties) {
        return completion(input);
    }
    
    SABaseEventObject *object = input.eventObject;
    NSString *eventName = object.event;
    NSMutableDictionary *properties = [input.properties mutableCopy];
    
    // item 操作，不采集用户 Id 信息
    BOOL isNeedCorrectUserId = [eventName isEqualToString:kSABTriggerEventName] || [eventName isEqualToString:SFPlanPopupDisplayEventName];
    if (![SAValidator isValidString:eventName] || !isNeedCorrectUserId) {
        return completion(input);
    }
    
    // $ABTestTrigger 事件修正
    if ([eventName isEqualToString:kSABTriggerEventName]) {
        // 修改 loginId, distinctId,anonymousId
        if (properties[kSABLoginId]) {
            object.loginId = properties[kSABLoginId];
            [properties removeObjectForKey:kSABLoginId];
        }
        
        if (properties[kSABDistinctId]) {
            object.distinctId = properties[kSABDistinctId];
            [properties removeObjectForKey:kSABDistinctId];
        }
        
        if (properties[kSABAnonymousId]) {
            object.anonymousId = properties[kSABAnonymousId];
            [properties removeObjectForKey:kSABAnonymousId];
        }
    }
    
    // $PlanPopupDisplay 事件修正
    if ([eventName isEqualToString:SFPlanPopupDisplayEventName]) {
        // 修改 loginId, distinctId,anonymousId
        if (properties[kSFLoginId]) {
            object.loginId = properties[kSFLoginId];
            [properties removeObjectForKey:kSFLoginId];
        }
        
        if (properties[kSFDistinctId]) {
            object.distinctId = properties[kSFDistinctId];
            [properties removeObjectForKey:kSFDistinctId];
        }
        
        if (properties[kSFAnonymousId]) {
            object.anonymousId = properties[kSFAnonymousId];
            [properties removeObjectForKey:kSFAnonymousId];
        }
    }
    
    input.properties = [properties copy];
    completion(input);
}

@end
