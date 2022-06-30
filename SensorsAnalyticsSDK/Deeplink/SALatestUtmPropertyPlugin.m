//
// SALatestUtmPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/4/26.
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

#import "SALatestUtmPropertyPlugin.h"
#import "SAModuleManager.h"
#import "SADeepLinkConstants.h"
#import "SAConstants+Private.h"

@implementation SALatestUtmPropertyPlugin

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    // 手动调用接口采集 $AppDeeplinkLaunch 事件, 不需要添加 $latest_utm_xxx 属性
    if ([self.filter.event isEqualToString:kSAAppDeepLinkLaunchEvent] && [self.filter.lib.method isEqualToString:kSALibMethodCode]) {
        return NO;
    }
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    return SAModuleManager.sharedInstance.latestUtmProperties;
}

@end
