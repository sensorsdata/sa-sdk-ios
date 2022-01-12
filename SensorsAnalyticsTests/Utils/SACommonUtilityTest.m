//
// SACommonUtilityTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/9/28.
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
#import "SACommonUtility.h"

@interface SACommonUtilityTest : XCTestCase

@end

@implementation SACommonUtilityTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSubByteWithEmptyString {
//   NSString *subByteString = [SACommonUtility subByteString:@"" byteLength:10];
//   XCTAssertTrue([subByteString isEqualToString:@""]);
}

- (void)testSubByteWithNilString {
//   XCTAssertNil([SACommonUtility subByteString:nil byteLength:10]);
}

- (void)testSubByteWithGreaterThanLengthString {
    NSString *subByteString = [SACommonUtility subByteString:@"123456789012" byteLength:10];
    XCTAssertTrue([subByteString isEqualToString:@"1234567890"]);
}

- (void)testSubByteWithEqualToLengthString {
    NSString *subByteString = [SACommonUtility subByteString:@"1234567890" byteLength:10];
    XCTAssertTrue([subByteString isEqualToString:@"1234567890"]);
}

- (void)testSubByteWithLessThanLengthString {
//   NSString *subByteString = [SACommonUtility subByteString:@"123456789" byteLength:10];
//   XCTAssertTrue([subByteString isEqualToString:@"123456789"]);
}

- (void)testSubByteWithChineseString {
    // utf8 汉字占三个字节
    NSString *subByteString = [SACommonUtility subByteString:@"123456789中" byteLength:10];
    XCTAssertTrue([subByteString isEqualToString:@"123456789"]);

    subByteString = [SACommonUtility subByteString:@"1234中56789" byteLength:10];
    XCTAssertTrue([subByteString isEqualToString:@"1234中567"]);
}

- (void)testSubByteWithZeroLength {
    NSString *subByteString = [SACommonUtility subByteString:@"123456789" byteLength:0];
    XCTAssertTrue([subByteString isEqualToString:@""]);
}

- (void)testSubByteWithNegativeLength {
//   NSString *subByteString = [SACommonUtility subByteString:@"123456789" byteLength:-5];
//   XCTAssertTrue([subByteString isEqualToString:@""]);
}

- (void)testSubByteWithEmojiString {
    NSString *subByteString = [SACommonUtility subByteString:@"123456789✅" byteLength:10];
    XCTAssertTrue([subByteString isEqualToString:@"123456789"]);

    subByteString = [SACommonUtility subByteString:@"1234✅56789" byteLength:10];
    XCTAssertTrue([subByteString isEqualToString:@"1234✅567"]);
}

- (void)testSaveNilUserAgent {
    [SACommonUtility saveUserAgent:nil];
    XCTAssertNil([SACommonUtility currentUserAgent]);
}

- (void)testSaveEmptyUserAgent {
    [SACommonUtility saveUserAgent:@""];
    XCTAssertNil([SACommonUtility currentUserAgent]);
}

- (void)testSaveNotStringUserAgent {
    NSString *userAgent = (NSString *)@[@1, @2];
    [SACommonUtility saveUserAgent:userAgent];
    XCTAssertNil([SACommonUtility currentUserAgent]);
}

- (void)testSaveStringUserAgent {
    [SACommonUtility saveUserAgent:@"CustomUserAgent"];
    XCTAssertTrue([[SACommonUtility currentUserAgent] isEqualToString:@"CustomUserAgent"]);
}

- (void)testHashStringWithNil {
    XCTAssertNil([SACommonUtility hashStringWithData:nil]);
}

- (void)testHashStringWithData {
    NSString *string = @"TestData";
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNotNil([SACommonUtility hashStringWithData:data]);
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
