//
// SAProfileEventObjectTests.m
// SensorsAnalyticsTests
//
// Created by yuqiang on 2021/4/26.
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

#import <XCTest/XCTest.h>
#import "SAProfileEventObject.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK.h"

@interface SAProfileEventObjectTests : XCTestCase

@end

@implementation SAProfileEventObjectTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:nil];
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testProfileEventObject {
    SAProfileEventObject *object = [[SAProfileEventObject alloc] initWithType:SA_PROFILE_SET];
    XCTAssertTrue([SA_PROFILE_SET isEqualToString:object.type]);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.lib.method]);
}

- (void)testProfileIncrementEventObjectValidKeyForChineseCharacters {
    SAProfileIncrementEventObject *object = [[SAProfileIncrementEventObject alloc] initWithType:SA_PROFILE_INCREMENT];
    NSError *error = nil;
    [object sensorsdata_validKey:@"测试_key" value:@"测试_value" error:&error];
    XCTAssertNotNil(error);
}

- (void)testProfileIncrementEventObjectValidKeyForArrayValue {
    SAProfileIncrementEventObject *object = [[SAProfileIncrementEventObject alloc] initWithType:SA_PROFILE_INCREMENT];
    NSError *error = nil;
    [object sensorsdata_validKey:@"test_key" value:@[@"test_value"] error:&error];
    XCTAssertNotNil(error);
}

- (void)testProfileIncrementEventObjectValidKeyForStringValue {
    SAProfileIncrementEventObject *object = [[SAProfileIncrementEventObject alloc] initWithType:SA_PROFILE_INCREMENT];
    NSError *error = nil;
    [object sensorsdata_validKey:@"test_key" value:@"test_value" error:&error];
    XCTAssertNotNil(error);
}

- (void)testProfileIncrementEventObjectValidKeyForNumberValue {
    SAProfileIncrementEventObject *object = [[SAProfileIncrementEventObject alloc] initWithType:SA_PROFILE_INCREMENT];
    NSError *error = nil;
    [object sensorsdata_validKey:@"test_key" value:@(123) error:&error];
    XCTAssertNil(error);
}

- (void)testProfileAppendEventObjectValidKeyForChineseCharacters {
    SAProfileAppendEventObject *object = [[SAProfileAppendEventObject alloc] initWithType:SA_PROFILE_APPEND];
    NSError *error = nil;
    [object sensorsdata_validKey:@"测试_key" value:@"测试_value" error:&error];
    XCTAssertNotNil(error);
}

- (void)testProfileAppendEventObjectValidKeyForArrayStringValue {
    SAProfileAppendEventObject *object = [[SAProfileAppendEventObject alloc] initWithType:SA_PROFILE_APPEND];
    NSError *error = nil;
    [object sensorsdata_validKey:@"test_key" value:@[@"test_value"] error:&error];
    XCTAssertNil(error);
}

- (void)testProfileAppendEventObjectValidKeyForArrayNumberValue {
    SAProfileAppendEventObject *object = [[SAProfileAppendEventObject alloc] initWithType:SA_PROFILE_APPEND];
    NSError *error = nil;
    [object sensorsdata_validKey:@"test_key" value:@[@(111)] error:&error];
    XCTAssertNotNil(error);
}

- (void)testProfileAppendEventObjectValidKeyForStringValue {
    SAProfileAppendEventObject *object = [[SAProfileAppendEventObject alloc] initWithType:SA_PROFILE_APPEND];
    NSError *error = nil;
    [object sensorsdata_validKey:@"test_key" value:@"test_value" error:&error];
    XCTAssertNotNil(error);
}

- (void)testProfileAppendEventObjectValidKeyForNumberValue {
    SAProfileAppendEventObject *object = [[SAProfileAppendEventObject alloc] initWithType:SA_PROFILE_APPEND];
    NSError *error = nil;
    [object sensorsdata_validKey:@"test_key" value:@(123) error:&error];
    XCTAssertNotNil(error);
}

@end
