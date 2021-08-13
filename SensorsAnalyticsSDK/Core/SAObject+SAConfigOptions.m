//
// SAObject+SAConfigOptions.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/6/30.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAObject+SAConfigOptions.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SALog.h"

@implementation SADatabase (SAConfigOptions)

- (NSUInteger)maxCacheSize {
#ifdef DEBUG
    if (NSClassFromString(@"XCTestCase")) {
        return 10000;
    }
#endif
    return [SensorsAnalyticsSDK sdkInstance].configOptions.maxCacheSize;
}

@end


#pragma mark -

@implementation SAEventFlush (SAConfigOptions)

- (BOOL)isDebugMode {
    return [[SensorsAnalyticsSDK sdkInstance] debugMode] != SensorsAnalyticsDebugOff;
}

- (NSURL *)serverURL {
    return [SensorsAnalyticsSDK sdkInstance].network.serverURL;
}

- (BOOL)flushBeforeEnterBackground {
    return SensorsAnalyticsSDK.sdkInstance.configOptions.flushBeforeEnterBackground;
}

- (BOOL)enableEncrypt {
#if TARGET_OS_IOS
    return [SensorsAnalyticsSDK sdkInstance].configOptions.enableEncrypt;
#else
    return NO;
#endif
}


- (NSString *)cookie {
    return [[SensorsAnalyticsSDK sdkInstance].network cookieWithDecoded:NO];
}

@end


#pragma mark -

@implementation SAEventTracker (SAConfigOptions)

- (BOOL)isDebugMode {
    return [[SensorsAnalyticsSDK sdkInstance] debugMode] != SensorsAnalyticsDebugOff;
}

- (SensorsAnalyticsNetworkType)networkTypePolicy {
    return SensorsAnalyticsSDK.sdkInstance.configOptions.flushNetworkPolicy;
}

- (NSInteger)flushBulkSize {
    return SensorsAnalyticsSDK.sdkInstance.configOptions.flushBulkSize;
}

@end
