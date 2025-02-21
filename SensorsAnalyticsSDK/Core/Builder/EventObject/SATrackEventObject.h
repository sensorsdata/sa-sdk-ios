//
// SATrackEventObject.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
/// AppCrashed、$AppRemoteConfigChanged 等预置事件
@interface SAPresetEventObject : SATrackEventObject

@end

/// 绑定 ID 事件
@interface SABindEventObject : SATrackEventObject

@end

/// 解绑 ID 事件
@interface SAUnbindEventObject : SATrackEventObject

@end

NS_ASSUME_NONNULL_END
