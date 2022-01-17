//
// SAPresetPropertyPlugin.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/9/7.
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
#import "SAPropertyPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAPresetPropertyPlugin : NSObject <SAPropertyPluginProtocol>

@property (atomic, strong) NSDictionary<NSString *, id> *properties;

- (instancetype)initWithLibVersion:(NSString *)libVersion;

@end

NS_ASSUME_NONNULL_END
