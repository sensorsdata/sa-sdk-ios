//
// SAChannelInfoPropertyPlugin.m
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

#import "SAChannelInfoPropertyPlugin.h"
#import "SAPropertyPlugin+SAPrivate.h"
#import "SAConstants+Private.h"
#import "SAModuleManager.h"
#import "SATrackEventObject.h"

@implementation SAChannelInfoPropertyPlugin

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    // 不支持 H5 打通事件
    // 开启 enableAutoAddChannelCallbackEvent 后，只有手动 track 事件包含渠道信息
    if ([filter hybridH5] || ![filter isKindOfClass:SACustomEventObject.class]) {
        return NO;
    }

    return filter.type & SAEventTypeTrack;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    if (!self.filter) {
        return nil;
    }

    return [SAModuleManager.sharedInstance channelInfoWithEvent:self.filter.event];
}
@end
