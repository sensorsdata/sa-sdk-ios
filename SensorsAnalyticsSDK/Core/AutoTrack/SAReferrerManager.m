//
// SAReferrerManager.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/12/9.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAReferrerManager.h"
#import "SAConstants+Private.h"

@interface SAReferrerManager ()

@property (nonatomic, copy, readwrite) NSDictionary *referrerProperties;
@property (nonatomic, copy, readwrite) NSString *referrerURL;
@property (nonatomic, copy, readwrite) NSString *referrerTitle;
@property (nonatomic, copy) NSString *currentTitle;

@end

@implementation SAReferrerManager

- (NSDictionary *)propertiesWithURL:(NSString *)currentURL eventProperties:(NSDictionary *)eventProperties serialQueue:(dispatch_queue_t)serialQueue {
    NSString *referrerURL = self.referrerURL;
    NSMutableDictionary *newProperties = [NSMutableDictionary dictionaryWithDictionary:eventProperties];

    // 客户自定义属性中包含 $url 时，以客户自定义内容为准
    if (!newProperties[SA_EVENT_PROPERTY_SCREEN_URL]) {
        newProperties[SA_EVENT_PROPERTY_SCREEN_URL] = currentURL;
    }
    // 客户自定义属性中包含 $referrer 时，以客户自定义内容为准
    if (referrerURL && !newProperties[SA_EVENT_PROPERTY_SCREEN_REFERRER_URL]) {
        newProperties[SA_EVENT_PROPERTY_SCREEN_REFERRER_URL] = referrerURL;
    }
    // $referrer 内容以最终页面浏览事件中的 $url 为准
    self.referrerURL = newProperties[SA_EVENT_PROPERTY_SCREEN_URL];
    self.referrerProperties = newProperties;

    dispatch_async(serialQueue, ^{
        [self cacheReferrerTitle:newProperties];
    });
    return newProperties;
}

- (void)cacheReferrerTitle:(NSDictionary *)properties {
    if (!self.enableReferrerTitle) {
        return;
    }
    self.referrerTitle = self.currentTitle;
    self.currentTitle = properties[SA_EVENT_PROPERTY_TITLE];
}

- (void)clearReferrer {
    if (self.isClearReferrer) {
        // 需求层面只需要清除 $referrer，不需要清除 $referrer_title
        self.referrerURL = nil;
    }
}

@end
