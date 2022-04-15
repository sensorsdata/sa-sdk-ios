//
// SAQueryDeepLinkProcessor.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2022/3/14.
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

#import "SAQueryDeepLinkProcessor.h"
#import "SADeepLinkConstants.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK+DeepLink.h"
#import "SAConstants+Private.h"
#import "SAURLUtils.h"
#import "SAIdentifier.h"
#import "SAJSONUtil.h"
#import "SANetwork.h"
#import "SAUserAgent.h"

@implementation SAQueryDeepLinkProcessor

// URL 的 Query 中包含一个或多个 utm_* 参数。示例：https://sensorsdata.cn?utm_content=1&utm_campaign=2
// utm_* 参数共五个，"utm_campaign", "utm_content", "utm_medium", "utm_source", "utm_term"
+ (BOOL)isValidURL:(NSURL *)url customChannelKeys:(NSSet *)customChannelKeys {
    NSMutableSet *sets = [NSMutableSet setWithSet:customChannelKeys];
    [sets unionSet:sensorsdata_preset_channel_keys()];
    NSDictionary *queryItems = [SAURLUtils queryItemsWithURL:url];
    for (NSString *key in sets) {
        if (queryItems[key]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canWakeUp {
    return YES;
}

- (void)startWithProperties:(NSDictionary *)properties {
    NSDictionary *queryItems = [SAURLUtils queryItemsWithURL:self.URL];
    NSDictionary *channels = [self acquireChannels:queryItems];
    NSDictionary *latestChannels = [self acquireLatestChannels:queryItems];
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    [eventProperties addEntriesFromDictionary:properties];
    [eventProperties addEntriesFromDictionary:channels];
    [eventProperties addEntriesFromDictionary:latestChannels];
    [self trackDeepLinkLaunch:eventProperties];

    if ([self.delegate respondsToSelector:@selector(sendChannels:latestChannels:isDeferredDeepLink:)]) {
        [self.delegate sendChannels:channels latestChannels:latestChannels isDeferredDeepLink:NO];
    }
}
@end
