//
// SAAppTrackerProtocol.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/20.
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SAAppTrackerProtocol <NSObject>

/// 是否忽略事件
@property (nonatomic, assign, getter=isIgnored) BOOL ignored;

/// 获取 tracker 对应的事件名
+ (NSString *)eventName;

/// 触发全埋点事件
/// @param properties 事件属性
- (void)trackEventWithProperties:(nullable NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
