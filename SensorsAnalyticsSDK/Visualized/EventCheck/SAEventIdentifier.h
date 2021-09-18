//
// SAEventIdentifier.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/3/23.
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

#import "SAVisualPropertiesConfig.h"
#import "SensorsAnalyticsSDK+Private.h"

NS_ASSUME_NONNULL_BEGIN

/// 事件标识
@interface SAEventIdentifier : SAViewIdentifier

/// 事件名
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, strong) NSMutableDictionary *properties;

- (instancetype)initWithEventInfo:(NSDictionary *)eventInfo;

@end

NS_ASSUME_NONNULL_END
