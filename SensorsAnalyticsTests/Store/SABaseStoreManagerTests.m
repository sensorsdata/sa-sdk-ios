//
// SABaseStoreManagerTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2021/12/3.
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

#import <XCTest/XCTest.h>
#import "SAAESStorePlugin.h"
#import "SAFileStorePlugin.h"
#import "SAUserDefaultsStorePlugin.h"
#import "SABaseStoreManager.h"

static NSString * const kSABaseStoreManagerTestsKey = @"SABaseStoreManagerTests";

@interface SABaseStoreManagerTests : XCTestCase

@property (nonatomic, strong) SAAESStorePlugin *aesPlugin;

@property (nonatomic, strong) SAFileStorePlugin *filePlugin;

@property (nonatomic, strong) SAUserDefaultsStorePlugin *userDefaultsPlugin;

@property (nonatomic, strong) SABaseStoreManager *manager;

@end

@implementation SABaseStoreManagerTests

- (void)setUp {
    _aesPlugin = [[SAAESStorePlugin alloc] init];
    _filePlugin = [[SAFileStorePlugin alloc] init];
    _userDefaultsPlugin = [[SAUserDefaultsStorePlugin alloc] init];

    _manager = [[SABaseStoreManager alloc] init];

    [_manager registerStorePlugin:_filePlugin];
    [_manager registerStorePlugin:_userDefaultsPlugin];
//   [_manager registerStorePlugin:_aesPlugin];
}

- (void)tearDown {
    [_aesPlugin removeObjectForKey:kSABaseStoreManagerTestsKey];
    _aesPlugin = nil;

    [_filePlugin removeObjectForKey:kSABaseStoreManagerTestsKey];
    _filePlugin = nil;

    [_userDefaultsPlugin removeObjectForKey:kSABaseStoreManagerTestsKey];
    _userDefaultsPlugin = nil;

    _manager = nil;
}

#pragma mark - Set

- (void)testSetStringObject {
    NSString *object = @"123";
    [self.manager setObject:object forKey:kSABaseStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToString:[self.manager objectForKey:kSABaseStoreManagerTestsKey]]);
}

- (void)testSetArrayObject {
    NSArray *object = @[@"123", @"哈哈哈dabn"];
    [self.manager setObject:object forKey:kSABaseStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToArray:[self.manager objectForKey:kSABaseStoreManagerTestsKey]]);
}

- (void)testSetDictionaryObject {
    NSDictionary *object = @{@"login_id": @"123"};
    [self.manager setObject:object forKey:kSABaseStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToDictionary:[self.manager objectForKey:kSABaseStoreManagerTestsKey]]);
}

- (void)testSetDataObject {
    NSData *object = [kSABaseStoreManagerTestsKey dataUsingEncoding:NSUTF8StringEncoding];
    [self.manager setObject:object forKey:kSABaseStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToData:[self.manager objectForKey:kSABaseStoreManagerTestsKey]]);
}

- (void)testSetIntegerNumberObject {
    NSNumber *object = @(123);
    [self.manager setObject:object forKey:kSABaseStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.manager objectForKey:kSABaseStoreManagerTestsKey]]);
}

- (void)testSetFloatNumberObject {
    NSNumber *object = @((float)1233.0);
    [self.manager setObject:object forKey:kSABaseStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.manager objectForKey:kSABaseStoreManagerTestsKey]]);
}

- (void)testSetDoubleNumberObject {
    NSNumber *object = @(122223.00000);
    [self.manager setObject:object forKey:kSABaseStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.manager objectForKey:kSABaseStoreManagerTestsKey]]);
}

- (void)testSetBoolObject {
    NSNumber *object = @(YES);
    [self.manager setObject:object forKey:kSABaseStoreManagerTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.manager objectForKey:kSABaseStoreManagerTestsKey]]);
}

//- (void)testSetNullObject {
//   NSNull *object = [NSNull null];
//   [self.manager setObject:object forKey:kSABaseStoreManagerTestsKey];
//   XCTAssertTrue([object isEqual:[self.manager objectForKey:kSABaseStoreManagerTestsKey]]);
//}

- (void)testRemoveObjectForKey {
    NSString *object = @"123";
    [self.manager setObject:object forKey:kSABaseStoreManagerTestsKey];
    [self.manager removeObjectForKey:kSABaseStoreManagerTestsKey];
    XCTAssertNil([self.manager objectForKey:kSABaseStoreManagerTestsKey]);
}

#pragma mark - Performance

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        NSString *object = kSABaseStoreManagerTestsKey;
        [self.manager setObject:object forKey:kSABaseStoreManagerTestsKey];
        [self.manager objectForKey:kSABaseStoreManagerTestsKey];
        [self.manager removeObjectForKey:kSABaseStoreManagerTestsKey];
    }];
}

@end
