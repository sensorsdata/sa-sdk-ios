//
// SAEventLibObjectTests.m
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
#import "SAEventLibObject.h"
#import "SensorsAnalyticsSDK.h"

@interface SAEventLibObjectTests : XCTestCase

@end

@implementation SAEventLibObjectTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:nil];
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testEventLibObject {
    SAEventLibObject *object = [[SAEventLibObject alloc] init];
    XCTAssertNotNil(object.lib);
    XCTAssertNotNil(object.method);
    XCTAssertNotNil(object.version);
}

- (void)testSetStringMethod {
    SAEventLibObject *object = [[SAEventLibObject alloc] init];
    id method = @"123";
    object.method = method;
    XCTAssertTrue([method isEqualToString:object.method]);
}

- (void)testSetArrayMethod {
    SAEventLibObject *object = [[SAEventLibObject alloc] init];
    id method = @[@"123"];
    object.method = method;
    XCTAssertTrue(![method isEqual:object.method]);
}

- (void)testSetObjectMethod {
    SAEventLibObject *object = [[SAEventLibObject alloc] init];
    id method = [[NSObject alloc] init];
    object.method = method;
    XCTAssertTrue(![method isEqual:object.method]);
}

- (void)testSetNumberMethod {
    SAEventLibObject *object = [[SAEventLibObject alloc] init];
    id method = @(123);
    object.method = method;
    XCTAssertTrue(![method isEqual:object.method]);
}

- (void)testJsonObject {
    SAEventLibObject *object = [[SAEventLibObject alloc] init];
    XCTAssertTrue(object.jsonObject.count > 0);
}

@end
