//
// SAValidatorTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/9.
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
#import "SAValidator.h"

@interface SAValidatorTest : XCTestCase

@end

@implementation SAValidatorTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testValidStringWithEmptyString {
    XCTAssertTrue(![SAValidator isValidString:@""]);
}

- (void)testValidStringWithNilString {
    NSString *str = nil;
    XCTAssertTrue(![SAValidator isValidString:str]);
}

- (void)testValidStringWithEnglishString {
    XCTAssertTrue([SAValidator isValidString:@"A"]);
}

- (void)testValidStringWithNumberString {
    XCTAssertTrue([SAValidator isValidString:@"1"]);
}

- (void)testValidStringWithChineseString {
    XCTAssertTrue([SAValidator isValidString:@"中"]);
}

- (void)testValidStringWithEmojiString {
    XCTAssertTrue([SAValidator isValidString:@"✅"]);
}

- (void)testValidStringWithCombinedString {
    XCTAssertTrue([SAValidator isValidString:@"A1中✅"]);
}

- (void)testValidStringWithNotString {
    NSArray *arr = @[@1, @2];
    XCTAssertTrue(![SAValidator isValidString:(NSString *)arr]);
}

- (void)testValidDictionaryWithEmptyDictionary {
    XCTAssertTrue(![SAValidator isValidDictionary:[NSDictionary dictionary]]);
}

- (void)testValidDictionaryWithNilDictionary {
    NSDictionary *dic = nil;
    XCTAssertTrue(![SAValidator isValidDictionary:dic]);
}

- (void)testValidDictionaryWithDictionary {
    NSDictionary *dic = @{@"A" : @"a"};
    XCTAssertTrue([SAValidator isValidDictionary:dic]);
}

- (void)testValidDictionaryWithEmptyMutableDictionary {
    XCTAssertTrue(![SAValidator isValidDictionary:[NSMutableDictionary dictionary]]);
}

- (void)testValidDictionaryWithNilMutableDictionary {
    NSMutableDictionary *mDic = nil;
    XCTAssertTrue(![SAValidator isValidDictionary:mDic]);
}

- (void)testValidDictionaryWithMutableDictionary {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
    mDic[@"A"] = @"a";
    XCTAssertTrue([SAValidator isValidDictionary:mDic]);
}

- (void)testValidDictionaryWithNotDictionary {
    NSArray *arr = @[@1, @2];
    XCTAssertTrue(![SAValidator isValidDictionary:(NSDictionary *)arr]);
}

- (void)testValidArrayWithEmptyArray {
    XCTAssertTrue(![SAValidator isValidArray:[NSArray array]]);
}

- (void)testValidArrayWithNilArray {
    NSArray *arr = nil;
    XCTAssertTrue(![SAValidator isValidArray:arr]);
}

- (void)testValidArrayWithArray {
    NSArray *arr = @[@1, @2];
    XCTAssertTrue([SAValidator isValidArray:arr]);
}

- (void)testValidArrayWithEmptyMutableArray {
    XCTAssertTrue(![SAValidator isValidArray:[NSMutableArray array]]);
}

- (void)testValidArrayWithNilMutableArray {
    NSMutableArray *mArr = nil;
    XCTAssertTrue(![SAValidator isValidArray:mArr]);
}

- (void)testValidArrayWithMutableArray {
    NSMutableArray *mArr = [NSMutableArray array];
    [mArr addObject:@"A"];
    XCTAssertTrue([SAValidator isValidArray:mArr]);
}

- (void)testValidArrayWithNotArray {
    NSString *arr = @"A";
    XCTAssertTrue(![SAValidator isValidArray:(NSArray *)arr]);
}

- (void)testValidDataWithEmptyData {
    XCTAssertTrue(![SAValidator isValidData:[NSData data]]);
}

- (void)testValidDataWithNilData {
    NSData *data = nil;
    XCTAssertTrue(![SAValidator isValidData:data]);
}

- (void)testValidDataWithData {
    NSData *data = [@"A" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertTrue([SAValidator isValidData:data]);
}

- (void)testValidDataWithEmptyMutableData {
    XCTAssertTrue(![SAValidator isValidData:[NSMutableData data]]);
}

- (void)testValidDataWithNilMutableData {
    NSMutableData *mData = nil;
    XCTAssertTrue(![SAValidator isValidData:mData]);
}

- (void)testValidDataWithMutableData {
    NSData *data = [@"A" dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *mData = [NSMutableData dataWithData:data];
    XCTAssertTrue([SAValidator isValidData:mData]);
}

- (void)testValidDataWithNotData {
    NSString *data= @"A";
    XCTAssertTrue(![SAValidator isValidData:(NSData *)data]);
}

- (void)testValidKeyWithEmptyKey {
    NSError *error = nil;
    [SAValidator validKey:@"" error:&error];
    XCTAssertNotNil(error);
}

- (void)testValidKeyWithNilKey {
    NSString *key= nil;
    NSError *error = nil;
    [SAValidator validKey:key error:&error];
    XCTAssertNotNil(error);
}

- (void)testValidKeyWithChineseKey {
    NSError *error = nil;
    [SAValidator validKey:@"中" error:&error];
    XCTAssertNotNil(error);
}

- (void)testValidKeyWithEmojiKey {
    NSError *error = nil;
    [SAValidator validKey:@"✅" error:&error];
    XCTAssertNotNil(error);
}

- (void)testValidKeyWithSpecialKey {
    NSError *error = nil;
    [SAValidator validKey:@"ABC~!" error:&error];
    XCTAssertNotNil(error);
}

- (void)testValidKeyWithNumberStartKey {
    NSError *error = nil;
    [SAValidator validKey:@"098Aa_$1" error:&error];
    XCTAssertNotNil(error);
}

- (void)testValidKeyWithUnderlineStartKey {
    NSError *error = nil;
    [SAValidator validKey:@"_098Aa$1" error:&error];
    XCTAssertNil(error);
}

- (void)testValidKeyWithLetterStartKey {
    NSError *error = nil;
    [SAValidator validKey:@"Aa098_$1" error:&error];
    XCTAssertNil(error);
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
