//
// SAStoreManagerTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2021/12/31.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
