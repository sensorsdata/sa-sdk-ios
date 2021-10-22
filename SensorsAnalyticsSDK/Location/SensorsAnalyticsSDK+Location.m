//
// SensorsAnalyticsSDK+Location.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/11.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK+Location.h"
#import "SALocationManager.h"

@implementation SensorsAnalyticsSDK (Location)

- (void)enableTrackGPSLocation:(BOOL)enable {
    if (NSThread.isMainThread) {
        [SALocationManager defaultManager].enable = enable;
        [SALocationManager defaultManager].configOptions.enableLocation = enable;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [SALocationManager defaultManager].enable = enable;
            [SALocationManager defaultManager].configOptions.enableLocation = enable;
        });
    }
}

@end
