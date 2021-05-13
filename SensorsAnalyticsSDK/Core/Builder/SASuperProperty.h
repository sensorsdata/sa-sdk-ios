//
// SASuperProperty.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/10.
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

@interface SASuperProperty : NSObject

/// 注册公共属性
/// @param propertyDict 公共属性
- (void)registerSuperProperties:(NSDictionary *)propertyDict;

/// 注销公共属性
/// @param property 公共属性的 key
- (void)unregisterSuperProperty:(NSString *)property;

/// 获取当前的公共属性
- (NSDictionary *)currentSuperProperties;

/// 清空公共属性
- (void)clearSuperProperties;

/// 从当前公共属性中移除 key (忽略大小写) 相同的属性
/// @param propertyDict 对比的属性字典
- (void)unregisterSameLetterSuperProperties:(NSDictionary *)propertyDict;

/// 注册动态公共属性
/// @param dynamicSuperProperties 动态公共属性的回调
- (void)registerDynamicSuperProperties:(NSDictionary<NSString *, id> *(^)(void)) dynamicSuperProperties;

/// 获取动态公共属性
- (NSDictionary *)acquireDynamicSuperProperties;

@end

NS_ASSUME_NONNULL_END
