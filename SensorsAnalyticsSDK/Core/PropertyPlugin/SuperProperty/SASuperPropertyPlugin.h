//
// SASuperPropertyPlugin.h
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/4/22.
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

/// 静态公共属性采集插件
@interface SASuperPropertyPlugin : SAPropertyPlugin

/// 注册公共属性
- (void)registerSuperProperties:(NSDictionary *)propertyDict;

/// 移除某个公共属性
///
/// @param property 属性的 key
- (void)unregisterSuperProperty:(NSString *)property;

/// 清空公共属性
- (void)clearSuperProperties;

/// 注销仅大小写不同的 SuperProperties
/// @param propertyDict 需要校验的属性
- (void)unregisterSameLetterSuperProperties:(NSDictionary *)propertyDict;

@end

NS_ASSUME_NONNULL_END
