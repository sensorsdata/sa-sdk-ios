//
// SAPropertyPlugin+SAPrivate.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/24.
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

#import "SAPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAPropertyPlugin ()

@property (nonatomic, strong, nullable) id<SAPropertyPluginEventFilter> filter;

@property (nonatomic, copy) NSDictionary<NSString *, id> *properties;
@property (nonatomic, copy) SAPropertyPluginHandler handler;

@end

NS_ASSUME_NONNULL_END
