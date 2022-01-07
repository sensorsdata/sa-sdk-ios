//
// SANSStringHashCodeTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/13.
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
#import "NSString+HashCode.h"

@interface SANSStringHashCodeTest : XCTestCase

@end

@implementation SANSStringHashCodeTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testHashCodeWithEmptyString {
    NSString *str = @"";
    XCTAssertEqual([str sensorsdata_hashCode], 0);
}

- (void)testHashCodeWithNilString {
    NSString *str = nil;
    XCTAssertEqual([str sensorsdata_hashCode], 0);
}

- (void)testHashCodeWithEqualEnglishString {
    XCTAssertEqual([@"Hello" sensorsdata_hashCode], [@"Hello" sensorsdata_hashCode]);
}

- (void)testHashCodeWithNotEqualEnglishString {
    XCTAssertNotEqual([@"Hello" sensorsdata_hashCode], [@"llo" sensorsdata_hashCode]);
}

- (void)testHashCodeWithEqualChineseString {
    XCTAssertEqual([@"Hello你好" sensorsdata_hashCode], [@"Hello你好" sensorsdata_hashCode]);
}

- (void)testHashCodeWithNotEqualChineseString {
    XCTAssertNotEqual([@"Hello你好" sensorsdata_hashCode], [@"Hello好" sensorsdata_hashCode]);
}

- (void)testHashCodeWithEqualEmojiString {
    XCTAssertEqual([@"🔥sd🙂哈哈😆" sensorsdata_hashCode], [@"🔥sd🙂哈哈😆" sensorsdata_hashCode]);
}

- (void)testHashCodeWithNotEqualEmojiString {
    XCTAssertNotEqual([@"🔥sd🙂哈哈😆" sensorsdata_hashCode], [@"🔥sd🙂" sensorsdata_hashCode]);
}

- (void)testHashCodeWithEqualSpecialString {
    XCTAssertEqual([@"^*&()%^)$*#!@#!#@" sensorsdata_hashCode], [@"^*&()%^)$*#!@#!#@" sensorsdata_hashCode]);
}

- (void)testHashCodeWithNotEqualSpecialString {
    XCTAssertNotEqual([@"^*&()%^)$*#!@#!#@" sensorsdata_hashCode], [@"^*&()%^)$*#!@#!" sensorsdata_hashCode]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
