//
// SAFileStore.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/1/6.
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

#import "SAFileStore.h"
#import "SALog.h"

@implementation SAFileStore

#pragma mark - archive file
+ (BOOL)archiveWithFileName:(NSString *)fileName value:(id)value {
    if (!fileName) {
        SALogError(@"key should not be nil for file store");
        return NO;
    }
    NSString *filePath = [SAFileStore filePath:fileName];
    /* 为filePath文件设置保护等级 */
    NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                           forKey:NSFileProtectionKey];
    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    if (![NSKeyedArchiver archiveRootObject:value toFile:filePath]) {
        SALogError(@"%@ unable to archive %@", self, fileName);
        return NO;
    }
    SALogDebug(@"%@ archived %@", self, fileName);
    return YES;
}

#pragma mark - unarchive file
+ (id)unarchiveWithFileName:(NSString *)fileName {
    if (!fileName) {
        SALogError(@"key should not be nil for file store");
        return nil;
    }
    NSString *filePath = [SAFileStore filePath:fileName];
    return [SAFileStore unarchiveFromFile:filePath];
}

+ (id)unarchiveFromFile:(NSString *)filePath {
    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    } @catch (NSException *exception) {
        SALogError(@"%@ unable to unarchive data in %@, starting fresh", self, filePath);
        unarchivedData = nil;
    }
    return unarchivedData;
}

#pragma mark - file path
+ (NSString *)filePath:(NSString *)key {
    NSString *filename = [NSString stringWithFormat:@"sensorsanalytics-%@.plist", key];
    NSString *filepath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
    SALogDebug(@"filepath for %@ is %@", key, filepath);
    return filepath;
}

@end
