//
// SABaseEventObject+RemoteConfig.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/6/7.
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

#import "SABaseEventObject+RemoteConfig.h"
#import "SARemoteConfigManager.h"
#import "SALog.h"

@implementation SABaseEventObject (RemoteConfig)

- (BOOL)isIgnoredByRemoteConfig {
    if ([SARemoteConfigManager sharedInstance].isDisableSDK) {
        SALogDebug(@"【remote config】SDK is disabled");
        return YES;
    }

    if ([[SARemoteConfigManager sharedInstance] isBlackListContainsEvent:self.event]) {
        SALogDebug(@"【remote config】 %@ is ignored by remote config", self.event);
        return YES;
    }

    return NO;
}

@end
