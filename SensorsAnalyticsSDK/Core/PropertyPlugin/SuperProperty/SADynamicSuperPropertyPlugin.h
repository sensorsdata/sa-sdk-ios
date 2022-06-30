//
// SADynamicSuperPropertyPlugin.h
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/4/24.
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

typedef NSDictionary<NSString *, id> *_Nullable(^SADynamicSuperPropertyBlock)(void);

/// 动态公共属性采集插件
@interface SADynamicSuperPropertyPlugin : SAPropertyPlugin

/// 动态公共属性采集插件实例
+ (SADynamicSuperPropertyPlugin *)sharedDynamicSuperPropertyPlugin;

/// 注册动态公共属性
///
/// @param dynamicSuperPropertiesBlock 动态公共属性的回调
- (void)registerDynamicSuperPropertiesBlock:(SADynamicSuperPropertyBlock)dynamicSuperPropertiesBlock;

/// 准备采集动态公共属性
///
/// 需要在队列外执行
- (void)buildDynamicSuperProperties;

@end

NS_ASSUME_NONNULL_END
