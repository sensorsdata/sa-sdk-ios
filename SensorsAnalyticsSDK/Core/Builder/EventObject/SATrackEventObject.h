//
// SATrackEventObject.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/6.
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

#import "SABaseEventObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SATrackEventObject : SABaseEventObject

- (instancetype)initWithEventId:(NSString *)eventId NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

@interface SASignUpEventObject : SATrackEventObject

@end

@interface SACustomEventObject : SATrackEventObject

@end

/// 自动采集全埋点事件：
/// $AppStart、$AppEnd、$AppViewScreen、$AppClick
@interface SAAutoTrackEventObject : SATrackEventObject

@end

/// 采集预置事件
/// $AppStart、$AppEnd、$AppViewScreen、$AppClick 全埋点事件
///  AppCrashed、$AppRemoteConfigChanged 等预置事件
@interface SAPresetEventObject : SATrackEventObject

@end

NS_ASSUME_NONNULL_END
