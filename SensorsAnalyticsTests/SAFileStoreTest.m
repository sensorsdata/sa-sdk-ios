//
// SAFileStoreTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/27.
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
#import "SAFileStore.h"

@interface SAFileStoreTest : XCTestCase

@end

@implementation SAFileStoreTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testArchiveWithEmptyFileName {
    XCTAssertTrue([SAFileStore archiveWithFileName:@"" value:@"value"]);
    XCTAssertTrue([[SAFileStore unarchiveWithFileName:@""] isEqualToString:@"value"]);
}

- (void)testArchiveWithNilFileName {
    NSString *fileName = nil;
    XCTAssertFalse([SAFileStore archiveWithFileName:fileName value:@"value"]);
}

- (void)testArchiveWithNotStringFileName {
    NSString *fileName = (NSString *)@[@1, @2];
    XCTAssertTrue([SAFileStore archiveWithFileName:fileName value:@"value"]);
    XCTAssertTrue([[SAFileStore unarchiveWithFileName:fileName] isEqualToString:@"value"]);
}

- (void)testArchiveWithStringFileName {
    XCTAssertTrue([SAFileStore archiveWithFileName:@"fileName" value:@"value"]);
    XCTAssertTrue([[SAFileStore unarchiveWithFileName:@"fileName"] isEqualToString:@"value"]);
}

- (void)testArchiveWithEmptyValue {
    XCTAssertTrue([SAFileStore archiveWithFileName:@"fileName" value:@""]);
    XCTAssertTrue([[SAFileStore unarchiveWithFileName:@"fileName"] isEqualToString:@""]);
}

- (void)testArchiveWithNilValue {
    NSString *value = nil;
    XCTAssertTrue([SAFileStore archiveWithFileName:@"fileName" value:value]);
    XCTAssertNil([SAFileStore unarchiveWithFileName:@"fileName"]);
}

- (void)testArchiveWithValue {
    XCTAssertTrue([SAFileStore archiveWithFileName:@"fileName" value:@{@"A" : @"B"}]);
    XCTAssertTrue([[SAFileStore unarchiveWithFileName:@"fileName"] isEqualToDictionary:@{@"A" : @"B"}]);
}

- (void)testArchiveWithEmptyFilePath {
    XCTAssertNotNil([SAFileStore filePath:@""]);
}

- (void)testArchiveWithNilFilePath {
    NSString *fileName = nil;
    XCTAssertNotNil([SAFileStore filePath:fileName]);
}

- (void)testArchiveWithNotStringFilePath {
    NSString *fileName = (NSString *)@[@1, @2];
    XCTAssertNotNil([SAFileStore filePath:fileName]);
}

- (void)testArchiveWithStringFilePath {
    XCTAssertNotNil([SAFileStore filePath:@"ABC"]);
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
