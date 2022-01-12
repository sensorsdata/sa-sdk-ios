//
// SAAESStorePlugin.m
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

#import "SAAESStorePlugin.h"
#import "SAAESCrypt.h"
#import "SAFileStorePlugin.h"

static NSString * const kSAAESStorePluginKey = @"StorePlugin.AES";

@interface SAAESStorePlugin ()

@property (nonatomic, strong) NSData *encryptKey;

@property (nonatomic, strong) SAFileStorePlugin *fileStorePlugin;

@property (nonatomic, strong) SAAESCrypt *aesCrypt;

@end

@implementation SAAESStorePlugin

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileStorePlugin = [[SAFileStorePlugin alloc] init];
    }
    return self;
}

#pragma mark - Key

- (NSData *)encryptKey {
    if (!_encryptKey) {
        NSData *data = [self.fileStorePlugin objectForKey:kSAAESStorePluginKey];
        if (data) {
            _encryptKey = [[NSData alloc] initWithBase64EncodedData:data options:0];
        }
    }
    return _encryptKey;
}

- (SAAESCrypt *)aesCrypt {
    if (!_aesCrypt) {
        _aesCrypt = [[SAAESCrypt alloc] initWithKey:self.encryptKey];
    }
    return _aesCrypt;
}

#pragma mark - Base 64

- (NSString *)base64KeyWithString:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}

#pragma mark - SAStorePlugin

- (nonnull NSString *)type {
    return @"cn.sensorsdata.AES128.";
}

- (void)upgradeWithOldPlugin:(nonnull id<SAStorePlugin>)oldPlugin {

}

- (nullable id)objectForKey:(nonnull NSString *)key {
    if (!self.encryptKey) {
        return nil;
    }
    NSString *base64Key = [self base64KeyWithString:key];
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:base64Key];
    if (!value) {
        return nil;
    }
    NSData *data = [self.aesCrypt decryptData:[value dataUsingEncoding:NSUTF8StringEncoding]];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (void)setObject:(nullable id)value forKey:(nonnull NSString *)key {
    if (!self.encryptKey) {
        self.encryptKey = self.aesCrypt.key;

        NSData *data = [self.encryptKey base64EncodedDataWithOptions:0];
        [self.fileStorePlugin setObject:data forKey:kSAAESStorePluginKey];
    }
    NSString *base64Key = [self base64KeyWithString:key];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
    NSString *encryptData = [self.aesCrypt encryptData:data];
    [[NSUserDefaults standardUserDefaults] setObject:encryptData forKey:base64Key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeObjectForKey:(nonnull NSString *)key {
    NSString *base64Key = [self base64KeyWithString:key];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:base64Key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
