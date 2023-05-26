//
// SensorsAnalyticsSDK+Exposure.h
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

#import "SensorsAnalyticsSDK.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK (Exposure)

/// use this method to add exposure to certain view
/// - Parameters:
///   - view: view to expose
///   - data: exposure data, such as event name, properties, etc.
- (void)addExposureView:(UIView *)view withData:(SAExposureData *)data;

/// remove exposure for certain view
/// - Parameters:
///   - view: view that need to remove exposure
///   - identifier: exposure identifier to identify certain view, if no identifier specified when addExposureView
- (void)removeExposureView:(UIView *)view withExposureIdentifier:(nullable NSString *)identifier;

/// update properties for certain view that need to expose
/// - Parameters:
///   - view: view to expose
///   - properties: properties to update
- (void)updateExposure:(UIView *)view withProperties:(NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
