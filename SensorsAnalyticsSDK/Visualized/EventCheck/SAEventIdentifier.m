//
// SAEventIdentifier.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/3/23.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAEventIdentifier.h"
#import "UIViewController+SAAutoTrack.h"
#import "SAConstants+Private.h"

@implementation SAEventIdentifier

- (instancetype)initWithEventInfo:(NSDictionary *)eventInfo {
    NSDictionary *dic = [SAEventIdentifier eventIdentifierDicWithEventInfo:eventInfo];
    self = [super initWithDictionary:dic];
    if (self) {
        _eventName = eventInfo[@"event"];
        _properties = [eventInfo[kSAEventProperties] mutableCopy];
    }
    return self;
}

+ (NSDictionary *)eventIdentifierDicWithEventInfo:(NSDictionary *)eventInfo {
    NSMutableDictionary *eventInfoDic = [NSMutableDictionary dictionary];
    eventInfoDic[@"element_path"] = eventInfo[kSAEventProperties][kSAEventPropertyElementPath];
    eventInfoDic[@"element_position"] = eventInfo[kSAEventProperties][kSAEventPropertyElementPosition];
    eventInfoDic[@"element_content"] = eventInfo[kSAEventProperties][kSAEventPropertyElementContent];
    eventInfoDic[@"screen_name"] = eventInfo[kSAEventProperties][kSAEventPropertyScreenName];
    return eventInfoDic;
}
@end
