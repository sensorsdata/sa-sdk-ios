//
// SAFileStorePlugin.m
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

#import "SAFileStorePlugin.h"
#import "SAMacHistoryFileStorePlugin.h"

#if __has_include("SAStoreManager.h")
#import "SAStoreManager.h"
#endif

static NSString * const kSAFileStorePluginType = @"cn.sensorsdata.File.";

@implementation SAFileStorePlugin

+ (NSString *)filePath:(NSString *)key {
    NSString *name = [key stringByReplacingOccurrencesOfString:kSAFileStorePluginType withString:@""];
#if TARGET_OS_OSX
    NSString *appId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *filename = [NSString stringWithFormat:@"sensorsanalytics-%@-%@.plist", appId, name];
#else
    NSString *filename = [NSString stringWithFormat:@"sensorsanalytics-%@.plist", name];
#endif

#if !TARGET_OS_TV
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
                          stringByAppendingPathComponent:filename];
#else
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
#endif

}

#pragma mark - SAStorePlugin

- (NSArray<NSString *> *)storeKeys {
    return @[@"$channel_device_info", @"login_id", @"distinct_id", @"com.sensorsdata.loginidkey", @"com.sensorsdata.identities", @"first_day", @"super_properties", @"latest_utms", @"SAEncryptSecretKey", @"SAVisualPropertiesConfig", @"SASessionModel"];
}

- (NSString *)type {
    return kSAFileStorePluginType;
}

// macOS 历史数据迁移
- (void)upgradeWithOldPlugin:(nonnull id<SAStorePlugin>)oldPlugin {
    if (![oldPlugin isKindOfClass:SAMacHistoryFileStorePlugin.class]) {
        return;
    }

    NSArray *storeKeys = [self storeKeys];
    for (NSString *key in storeKeys) {
        NSString *oldStoreKey = [NSString stringWithFormat:@"%@%@", oldPlugin.type, key];
        // 读取旧数据
        id historyValue = [oldPlugin objectForKey:oldStoreKey];
        if (!historyValue) {
            continue;
        }

        NSString *newStoreKey = [NSString stringWithFormat:@"%@%@", self.type, key];
        // 数据迁移到新插件
        [self setObject:historyValue forKey:newStoreKey];
        // 删除历史数据
        [oldPlugin removeObjectForKey:oldStoreKey];
    }

#if __has_include("SAStoreManager.h")
    // 迁移完成或，移除旧插件
    [SAStoreManager.sharedInstance unregisterStorePluginWithPluginClass:SAMacHistoryFileStorePlugin.class];
#endif
}

- (nullable id)objectForKey:(nonnull NSString *)key {
    if (!key) {
        return nil;
    }
    NSString *filePath = [SAFileStorePlugin filePath:key];
    @try {
        return [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    } @catch (NSException *exception) {
        return nil;
    }
}

- (void)setObject:(nullable id)value forKey:(nonnull NSString *)key {
    if (!key) {
        return;
    }
    // 屏蔽非法数据类型，防止野指针造成异常
    if(!value && ![value conformsToProtocol:@protocol(NSCoding)]) {
        return;
    }

    NSString *filePath = [SAFileStorePlugin filePath:key];
#if TARGET_OS_IOS
    /* 为filePath文件设置保护等级 */
    NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionNone
                                                           forKey:NSFileProtectionKey];
#else
    // macOS10.13 不包含 NSFileProtectionComplete
    NSDictionary *protection = [NSDictionary dictionary];
#endif

    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    [NSKeyedArchiver archiveRootObject:value toFile:filePath];
}

- (void)removeObjectForKey:(nonnull NSString *)key {
    NSString *filePath = [SAFileStorePlugin filePath:key];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
}

@end
