//
// SAUserDefaultsStorePlugin.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/12/1.
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

#import "SAUserDefaultsStorePlugin.h"

@implementation SAUserDefaultsStorePlugin

// 除当前的 Key 以为，还有 pushKey 会使用 UserDefaults
- (NSArray *)storeKeys {
    return @[@"HasTrackInstallationWithDisableCallback", @"HasTrackInstallation", @"com.sensorsdata.channeldebug.flag", @"SASDKConfig", @"SARequestRemoteConfigRandomTime", @"HasLaunchedOnce"];
}

- (nonnull NSString *)type {
    return @"cn.sensorsdata.UserDefaults.";
}

- (void)upgradeWithOldPlugin:(nonnull id<SAStorePlugin>)oldPlugin {

}

- (id)objectForKey:(NSString *)key {
    NSString *newKey = [key stringByReplacingOccurrencesOfString:self.type withString:@""];
    return [[NSUserDefaults standardUserDefaults] objectForKey:newKey];
}

- (void)setObject:(id)value forKey:(NSString *)key {
    NSString *newKey = [key stringByReplacingOccurrencesOfString:self.type withString:@""];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:value forKey:newKey];
    [userDefaults synchronize];
}

- (void)removeObjectForKey:(nonnull NSString *)key {
    NSString *newKey = [key stringByReplacingOccurrencesOfString:self.type withString:@""];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:newKey];
    [userDefaults synchronize];
}

@end
