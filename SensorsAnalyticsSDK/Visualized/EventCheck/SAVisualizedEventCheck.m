//
// SAVisualizedEventCheck.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/3/22.
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

#import "SAVisualizedEventCheck.h"
#import "SAConstants+Private.h"
#import "SAEventIdentifier.h"
#import "SALog.h"

NSString * const kSAWebVisualEventName = @"sensorsdata_web_visual_eventName";

@interface SAVisualizedEventCheck()
@property (nonatomic, strong) SAVisualPropertiesConfigSources *configSources;

/// 埋点校验缓存
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSString *,NSMutableArray <NSDictionary *> *>* eventCheckCache;
@end

@implementation SAVisualizedEventCheck

- (instancetype)initWithConfigSources:(SAVisualPropertiesConfigSources *)configSources;
{
    self = [super init];
    if (self) {
        _configSources = configSources;
        _eventCheckCache = [NSMutableDictionary dictionary];
        [self setupListeners];
    }
    return self;
}


- (void)setupListeners {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(trackEvent:) name:SA_TRACK_EVENT_NOTIFICATION object:nil];
    [notificationCenter addObserver:self selector:@selector(trackEventFromH5:) name:SA_TRACK_EVENT_H5_NOTIFICATION object:nil];
}

- (void)trackEvent:(NSNotification *)notification {
    if (![notification.userInfo isKindOfClass:NSDictionary.class]) {
        return;
    }

    NSDictionary *trackEventInfo = [notification.userInfo copy];
    // 构造事件标识
    SAEventIdentifier *eventIdentifier = [[SAEventIdentifier alloc] initWithEventInfo:trackEventInfo];
    // App 埋点校验，只支持 $AppClick 可视化全埋点事件
    if (![eventIdentifier.eventName isEqualToString:kSAEventNameAppClick]) {
        return;
    }

    // 查询事件配置，一个 $AppClick 事件，可能命中多个配置
    NSArray <SAVisualPropertiesConfig *>*configs = [self.configSources propertiesConfigsWithEventIdentifier:eventIdentifier];
    if (!configs) {
        return;
    }

    for (SAVisualPropertiesConfig *config in configs) {
        if (!config.event) {
            continue;
        }
        SALogDebug(@"调试模式，匹配到可视化全埋点事件 %@", config.eventName);
        [self cacheVisualEvent:config.eventName eventInfo:trackEventInfo];
    }
}

- (void)trackEventFromH5:(NSNotification *)notification {
    if (![notification.userInfo isKindOfClass:NSDictionary.class]) {
        return;
    }

    NSDictionary *trackEventInfo = notification.userInfo;
    // 构造事件标识
    SAEventIdentifier *eventIdentifier = [[SAEventIdentifier alloc] initWithEventInfo:trackEventInfo];
    //App 内嵌 H5 埋点校验，只支持 $WebClick 可视化全埋点事件
    if (![eventIdentifier.eventName isEqualToString:kSAEventNameWebClick]) {
        return;
    }

    // 针对 $WebClick 可视化全埋点事件，Web JS SDK 已做标记
    NSArray *webVisualEventNames = trackEventInfo[kSAEventProperties][kSAWebVisualEventName];
    if (!webVisualEventNames) {
        return;
    }
    // 移除标记
    eventIdentifier.properties[kSAWebVisualEventName] = nil;

    // 缓存 H5 可视化全埋点事件
    for (NSString *eventName in webVisualEventNames) {
        [self cacheVisualEvent:eventName eventInfo:trackEventInfo];
    }
}

/// 缓存可视化全埋点事件
- (void)cacheVisualEvent:(NSString *)eventName eventInfo:(NSDictionary *)eventInfo {
    if (!eventName) {
        return;
    }
    // 保存当前事件
    NSMutableArray *eventInfos = self.eventCheckCache[eventName];
    if (!eventInfos) {
        eventInfos = [NSMutableArray array];
        self.eventCheckCache[eventName] = eventInfos;
    }

    NSMutableDictionary *visualEventInfo = [eventInfo mutableCopy];
    visualEventInfo[@"event_name"] = eventName;
    [eventInfos addObject:visualEventInfo];
}

- (NSArray<NSDictionary *> *)eventCheckResult {
    NSMutableArray *allEventResult = [NSMutableArray array];
    for (NSArray *events in self.eventCheckCache.allValues) {
        [allEventResult addObjectsFromArray:events];
    }
    return [allEventResult copy];
}

- (void)cleanEventCheckResult {
    [self.eventCheckCache removeAllObjects];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
