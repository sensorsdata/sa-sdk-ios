//
// SAChannelInfoPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/4/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
