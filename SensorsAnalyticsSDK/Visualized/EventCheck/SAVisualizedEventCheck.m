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
}

- (void)trackEvent:(NSNotification *)notification {
    NSMutableDictionary *trackEventInfo = [notification.userInfo mutableCopy];
    if (trackEventInfo.count == 0) {
        return;
    }

    // 构造事件标识
    SAEventIdentifier *eventIdentifier = [[SAEventIdentifier alloc] initWithEventInfo:trackEventInfo];
    // 埋点校验，暂时只支持 $AppClick 事件
    if (eventIdentifier.eventType != SensorsAnalyticsEventTypeAppClick) {
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

        // 保存当前事件
        NSMutableArray *eventInfos = self.eventCheckCache[config.eventName];
        if (!eventInfos) {
            eventInfos = [NSMutableArray array];
            self.eventCheckCache[config.eventName] = eventInfos;
        }

        trackEventInfo[@"event_name"] = config.eventName;
        [eventInfos addObject:trackEventInfo];
    }
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
