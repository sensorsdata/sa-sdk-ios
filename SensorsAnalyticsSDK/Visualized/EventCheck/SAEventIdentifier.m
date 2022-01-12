//
// SAEventIdentifier.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/3/23.
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

#import "SAEventIdentifier.h"
#import "UIViewController+AutoTrack.h"
#import "SAConstants+Private.h"
#import "SAAutoTrackUtils.h"

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
