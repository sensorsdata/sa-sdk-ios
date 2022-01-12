//
// SAStoreManagerTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2021/12/31.
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

#import <XCTest/XCTest.h>
#import "SAAESStorePlugin.h"
#import "SAFileStorePlugin.h"
#import "SAUserDefaultsStorePlugin.h"
#import "SAStoreManager.h"

static NSString * const kSAStoreManagerTestsKey = @"SAStoreManagerTests";

@interface SAStoreManagerTests : XCTestCase

@property (nonatomic, strong) SAAESStorePlugin *aesPlugin;

@property (nonatomic, strong) SAFileStorePlugin *filePlugin;

@property (nonatomic, strong) SAUserDefaultsStorePlugin *userDefaultsPlugin;

@property (nonatomic, strong) SAStoreManager *manager;

@end

@implementation SAStoreManagerTests

- (void)setUp {
    _aesPlugin = [[SAAESStorePlugin alloc] init];
    _filePlugin = [[SAFileStorePlugin alloc] init];
    _userDefaultsPlugin = [[SAUserDefaultsStorePlugin alloc] init];

    _manager = [[SAStoreManager alloc] init];

    [_manager registerStorePlugin:_filePlugin];
    [_manager registerStorePlugin:_userDefaultsPlugin];
//
}

- (void)tearDown {
    [_aesPlugin removeObjectForKey:kSAStoreManagerTestsKey];
    _aesPlugin = nil;

    [_filePlugin removeObjectForKey:kSAStoreManagerTestsKey];
    _filePlugin = nil;

    [_userDefaultsPlugin removeObjectForKey:kSAStoreManagerTestsKey];
    _userDefaultsPlugin = nil;

    _manager = nil;
}

#pragma mark - AES

#pragma mark - Upgrade

- (void)testUpgradeFileToAES {
    [self.manager registerStorePlugin:_aesPlugin];

    NSString *object = kSAStoreManagerTestsKey;
    [self.filePlugin setObject:object forKey:kSAStoreManagerTestsKey];
    [self.manager setObject:object forKey:kSAStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToString:[self.manager objectForKey:kSAStoreManagerTestsKey]]);

    NSString *newKey = [NSString stringWithFormat:@"%@%@", self.aesPlugin.type, kSAStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToString:[self.aesPlugin objectForKey:newKey]]);
}

- (void)testUpgradeUserDefaultsToAES {
    [self.manager registerStorePlugin:_aesPlugin];

    NSString *object = kSAStoreManagerTestsKey;
    [self.userDefaultsPlugin setObject:object forKey:kSAStoreManagerTestsKey];
    [self.manager setObject:object forKey:kSAStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToString:[self.manager objectForKey:kSAStoreManagerTestsKey]]);

    NSString *newKey = [NSString stringWithFormat:@"%@%@", self.aesPlugin.type, kSAStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToString:[self.aesPlugin objectForKey:newKey]]);
}

#pragma mark - Key

- (void)testUseUserDefaultsKey {
    NSString *object = @"123";
    NSString *key = @"HasLaunchedOnce";
    [self.manager setObject:object forKey:key];
    XCTAssertTrue([object isEqualToString:[self.manager objectForKey:key]]);

    XCTAssertTrue([object isEqualToString:[self.userDefaultsPlugin objectForKey:key]]);
}

- (void)testRegisterCustomUseUserDefaultsKey {
    [self.manager registerStorePlugin:_aesPlugin];

    NSString *object = @"123";
    NSString *key = @"HasLaunchedOnce";
    [self.manager setObject:object forKey:key];
    XCTAssertTrue([object isEqualToString:[self.manager objectForKey:key]]);

    XCTAssertNil([self.userDefaultsPlugin objectForKey:key]);

    NSString *newKey = [NSString stringWithFormat:@"%@%@", self.aesPlugin.type, key];
    XCTAssertTrue([object isEqualToString:[self.aesPlugin objectForKey:newKey]]);
}

- (void)testUseFileStoreKey {
    NSString *object = @"123";
    NSString *key = @"$channel_device_info";
    [self.manager setObject:object forKey:key];
    XCTAssertTrue([object isEqualToString:[self.manager objectForKey:key]]);

    XCTAssertTrue([object isEqualToString:[self.filePlugin objectForKey:key]]);
}

- (void)testRegisterCustomUseFileStoreKey {
    [self.manager registerStorePlugin:_aesPlugin];

    NSString *object = @"123";
    NSString *key = @"$channel_device_info";
    [self.manager setObject:object forKey:key];
    XCTAssertTrue([object isEqualToString:[self.manager objectForKey:key]]);

    XCTAssertNil([self.filePlugin objectForKey:key]);

    NSString *newKey = [NSString stringWithFormat:@"%@%@", self.aesPlugin.type, key];
    XCTAssertTrue([object isEqualToString:[self.aesPlugin objectForKey:newKey]]);
}

@end
