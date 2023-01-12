//
// SADeepLinkProcessor.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/12/13.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "SADeepLinkProcessor.h"
#import "SADeepLinkConstants.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAIdentifier.h"
#import "SAQueryDeepLinkProcessor.h"
#import "SARequestDeepLinkProcessor.h"
#import "SADeepLinkEventProcessor.h"
#import "SADeferredDeepLinkProcessor.h"

@interface SADeepLinkLaunchEventObject : SAPresetEventObject

@end

@implementation SADeepLinkLaunchEventObject

// 手动调用接口采集 $AppDeeplinkLaunch 事件, 不需要添加 $latest_utm_xxx 属性
- (void)addLatestUtmProperties:(NSDictionary *)properties {
}

@end

@implementation SADeepLinkProcessor

+ (BOOL)isValidURL:(NSURL *)url customChannelKeys:(NSSet *)customChannelKeys {
    return NO;
}

- (BOOL)canWakeUp {
    return NO;
}

- (void)startWithProperties:(NSDictionary *)properties {

}

- (NSDictionary *)acquireChannels:(NSDictionary *)dictionary {
    // SDK 预置属性，示例：$utm_content 和 用户自定义属性
    return [self presetKeyPrefix:@"$" customKeyPrefix:@"" dictionary:dictionary];
}

- (NSDictionary *)acquireLatestChannels:(NSDictionary *)dictionary {
    // SDK 预置属性，示例：$latest_utm_content。
    // 用户自定义的属性，不是 SDK 的预置属性，因此以 _latest 开头，避免 SA 平台报错。示例：_lateset_customKey
    return [self presetKeyPrefix:@"$latest_" customKeyPrefix:@"_latest_" dictionary:dictionary];
}

- (NSDictionary *)presetKeyPrefix:(NSString *)presetKeyPrefix customKeyPrefix:(NSString *)customKeyPrefix dictionary:(NSDictionary *)dictionary {
    if (!presetKeyPrefix || !customKeyPrefix) {
        return @{};
    }

    NSMutableDictionary *channels = [NSMutableDictionary dictionary];
    for (NSString *item in dictionary.allKeys) {
        if ([sensorsdata_preset_channel_keys() containsObject:item]) {
            NSString *key = [NSString stringWithFormat:@"%@%@", presetKeyPrefix, item];
            channels[key] = [dictionary[item] stringByRemovingPercentEncoding];
        }
        if ([self.customChannelKeys containsObject:item]) {
            NSString *key = [NSString stringWithFormat:@"%@%@", customKeyPrefix, item];
            channels[key] = [dictionary[item] stringByRemovingPercentEncoding];
        }
    }
    return channels;
}

- (NSString *)appInstallSource {
    NSMutableDictionary *sources = [NSMutableDictionary dictionary];
    sources[@"idfa"] = [SAIdentifier idfa];
    sources[@"idfv"] = [SAIdentifier idfv];
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *key in sources.allKeys) {
        [result addObject:[NSString stringWithFormat:@"%@=%@", key, sources[key]]];
    }
    return [result componentsJoinedByString:@"##"];
}

- (void)trackDeepLinkLaunch:(NSDictionary *)properties {
    SADeepLinkLaunchEventObject *object = [[SADeepLinkLaunchEventObject alloc] initWithEventId:kSAAppDeepLinkLaunchEvent];
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    [eventProperties addEntriesFromDictionary:properties];
    eventProperties[kSAEventPropertyDeepLinkURL] = self.URL.absoluteString;
    eventProperties[kSAEventPropertyInstallSource] = [self appInstallSource];
    [SensorsAnalyticsSDK.sharedInstance trackEventObject:object properties:eventProperties];
}

- (void)trackDeepLinkMatchedResult:(NSDictionary *)properties {
    SAPresetEventObject *object = [[SAPresetEventObject alloc] initWithEventId:kSADeepLinkMatchedResultEvent];
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    [eventProperties addEntriesFromDictionary:properties];
    eventProperties[kSAEventPropertyDeepLinkURL] = self.URL.absoluteString;

    [SensorsAnalyticsSDK.sharedInstance trackEventObject:object properties:eventProperties];
}

@end

@implementation SADeepLinkProcessorFactory

+ (SADeepLinkProcessor *)processorFromURL:(NSURL *)url customChannelKeys:(NSSet *)customChannelKeys {
    SADeepLinkProcessor *object;
    if ([SARequestDeepLinkProcessor isValidURL:url customChannelKeys:customChannelKeys]) {
        object = [[SARequestDeepLinkProcessor alloc] init];
    } else if ([SAQueryDeepLinkProcessor isValidURL:url customChannelKeys:customChannelKeys]) {
        object = [[SAQueryDeepLinkProcessor alloc] init];
    } else {
        object = [[SADeepLinkProcessor alloc] init];
    }
    object.URL = url;
    object.customChannelKeys = customChannelKeys;
    return object;
}

@end
