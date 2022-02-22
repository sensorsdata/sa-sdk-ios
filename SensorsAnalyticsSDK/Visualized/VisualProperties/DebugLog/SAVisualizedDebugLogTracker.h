//
// SAVisualizedDebugLogTracker.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/3/3.
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

#import <Foundation/Foundation.h>
#import "SAEventIdentifier.h"
NS_ASSUME_NONNULL_BEGIN

/// 诊断日志
@interface SAVisualizedDebugLogTracker : NSObject

/// 所有日志信息
@property (atomic, strong, readonly) NSMutableArray<NSMutableDictionary *> *debugLogInfos;

/// 元素点击事件信息
- (void)addTrackEventWithView:(UIView *)view withConfig:(NSDictionary *)config;

@end

NS_ASSUME_NONNULL_END
