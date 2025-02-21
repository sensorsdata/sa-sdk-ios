//
// SAMacHistoryFileStorePlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2024/9/2.
// Copyright © 2015-2024 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAMacHistoryFileStorePlugin.h"

static NSString * const kSAMacHistoryFileStorePluginType = @"cn.sensorsdata.File.Mac.";


@implementation SAMacHistoryFileStorePlugin


+ (NSString *)filePath:(NSString *)key {
    NSString *name = [key stringByReplacingOccurrencesOfString:kSAMacHistoryFileStorePluginType withString:@""];
    // 兼容老版 macOS SDK 的本地数据
    NSString *filename = [NSString stringWithFormat:@"com.sensorsdata.analytics.mini.SensorsAnalyticsSDK.%@.plist", name];
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
                          stringByAppendingPathComponent:filename];
}

#pragma mark - SAStorePlugin

- (NSArray<NSString *> *)storeKeys {
    return @[@"$channel_device_info", @"login_id", @"distinct_id", @"com.sensorsdata.loginidkey", @"com.sensorsdata.identities", @"first_day", @"super_properties", @"latest_utms", @"SAEncryptSecretKey", @"SAVisualPropertiesConfig", @"SASessionModel"];
}

- (NSString *)type {
    return kSAMacHistoryFileStorePluginType;
}

- (void)upgradeWithOldPlugin:(nonnull id<SAStorePlugin>)oldPlugin {
}

- (nullable id)objectForKey:(nonnull NSString *)key {
    if (!key) {
        return nil;
    }
    NSString *filePath = [SAMacHistoryFileStorePlugin filePath:key];
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

    NSString *filePath = [SAMacHistoryFileStorePlugin filePath:key];

    // macOS10.13 不包含 NSFileProtectionComplete
    NSDictionary *protection = [NSDictionary dictionary];
    
    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    [NSKeyedArchiver archiveRootObject:value toFile:filePath];
}

- (void)removeObjectForKey:(nonnull NSString *)key {
    NSString *filePath = [SAMacHistoryFileStorePlugin filePath:key];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
}


@end
