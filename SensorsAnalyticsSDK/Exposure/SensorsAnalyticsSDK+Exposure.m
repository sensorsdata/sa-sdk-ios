//
// SensorsAnalyticsSDK+Exposure.m
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK+Exposure.h"
#import "SAExposureManager.h"

@implementation SensorsAnalyticsSDK (Exposure)

- (void)addExposureView:(UIView *)view withData:(SAExposureData *)data {
    [[SAExposureManager defaultManager] addExposureView:view withData:data];
}

- (void)removeExposureView:(UIView *)view withExposureIdentifier:(NSString *)identifier {
    [[SAExposureManager defaultManager] removeExposureView:view withExposureIdentifier:identifier];
}

- (void)updateExposure:(UIView *)view withProperties:(NSDictionary *)properties {
    [[SAExposureManager defaultManager] updateExposure:view withProperties:properties];
}

@end
