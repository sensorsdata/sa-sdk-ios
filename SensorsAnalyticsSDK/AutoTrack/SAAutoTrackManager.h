//
// SAAutoTrackManager.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/2.
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
#import "SAModuleProtocol.h"
#import "SAAppClickTracker.h"
#import "SAAppViewScreenTracker.h"
#import "SAAppPageLeaveTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (AutoTrackPrivate)

@property (nonatomic, assign) BOOL enableAutoTrack;

@end

@interface SAAutoTrackManager : NSObject <SAModuleProtocol, SAAutoTrackModuleProtocol>

@property (nonatomic, strong) SAConfigOptions *configOptions;
@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) SAAppClickTracker *appClickTracker;
@property (nonatomic, strong) SAAppViewScreenTracker *appViewScreenTracker;
@property (nonatomic, strong) SAAppPageLeaveTracker *appPageLeaveTracker;

+ (SAAutoTrackManager *)defaultManager;

#pragma mark - Public

/// 是否开启全埋点
- (BOOL)isAutoTrackEnabled;

/// 是否忽略某些全埋点
/// @param eventType 全埋点类型
- (BOOL)isAutoTrackEventTypeIgnored:(SensorsAnalyticsAutoTrackEventType)eventType;

/// 更新全埋点事件类型
- (void)updateAutoTrackEventType;

/// 校验可视化全埋点元素能否选中
/// @param obj 控件元素
/// @return 返回校验结果
- (BOOL)isGestureVisualView:(id)obj;

@end

NS_ASSUME_NONNULL_END
