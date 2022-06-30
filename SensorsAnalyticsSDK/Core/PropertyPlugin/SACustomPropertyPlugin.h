//
// SACustomPropertyPlugin.h
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

#import <Foundation/Foundation.h>
#import "SAPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

/// 自定义属性插件
/// 
/// 一般用于 track 事件传的属性
@interface SACustomPropertyPlugin : SAPropertyPlugin

/// 自定义属性插件初始化
///
/// @param properties 自定义属性
- (instancetype)initWithCustomProperties:(NSDictionary *)properties NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
