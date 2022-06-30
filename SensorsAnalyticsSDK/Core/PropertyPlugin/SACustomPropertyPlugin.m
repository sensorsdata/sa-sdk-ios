//
// SACustomPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/7.
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

#import "SACustomPropertyPlugin.h"
#import "SAValidator.h"
#import "SAPropertyValidator.h"
#import "SAConstants+Private.h"
#import "SAPropertyPlugin+SAPrivate.h"
#import "SAEventLibObject.h"

@interface SACustomPropertyPlugin()
/// 校验前的自定义属性原始内容
@property (nonatomic, copy) NSDictionary<NSString *, id> *originalProperties;
@end

@implementation SACustomPropertyPlugin

- (instancetype)initWithCustomProperties:(NSDictionary *)properties {
    self = [super init];
    if (self) {
        if ([SAValidator isValidDictionary:properties]) {
            self.originalProperties = properties;
        }
    }
    return self;
}

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    // item 和 profile 操作，也可能包含自定义属性
    return filter.type & SAEventTypeAll;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityDefault;
}

- (NSDictionary<NSString *,id> *)properties {

    // 属性校验
    NSMutableDictionary *props = [SAPropertyValidator validProperties:self.originalProperties];
    // profile 和 item 操作，不包含 $lib_method 属性
    // H5 打通事件，properties 中不包含 $lib_method
    if (self.filter.type > SAEventTypeDefault || self.filter.hybridH5) {
        return [props copy];
    }

    if (!props) {
        props  = [NSMutableDictionary dictionary];
    }
    // 如果传入自定义属性中的 $lib_method 为 String 类型，需要进行修正处理
    id libMethod = props[kSAEventPresetPropertyLibMethod];
    if ([self.filter.lib.method isEqualToString:kSALibMethodAuto]) {
        libMethod = kSALibMethodAuto;
    } else if (!libMethod || [libMethod isKindOfClass:NSString.class]) {
        if (![libMethod isEqualToString:kSALibMethodCode] &&
            ![libMethod isEqualToString:kSALibMethodAuto]) {
            libMethod = kSALibMethodCode;
        }
    }
    props[kSAEventPresetPropertyLibMethod] = libMethod;
    
    return [props copy];
}
@end
