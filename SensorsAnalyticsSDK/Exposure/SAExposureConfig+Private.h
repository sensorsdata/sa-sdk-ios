//
// SAExposureConfig+Private.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/9.
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

#import "SAExposureConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAExposureConfig (Private)

/// visable area rate, 0 ~ 1, default value is 0
@property (nonatomic, assign, readonly) CGFloat areaRate;

/// stay duration, default value is 0, unit is second
@property (nonatomic, assign, readonly) NSTimeInterval stayDuration;

/// allow repeated exposure or not, default value is YES
@property (nonatomic, assign, readonly) BOOL repeated;

@end

NS_ASSUME_NONNULL_END
