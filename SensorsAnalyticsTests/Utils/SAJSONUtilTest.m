//
// SAJSONUtilTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/9/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SAJSONUtil.h"

@interface SAJSONUtilTest : XCTestCase

@end

@implementation SAJSONUtilTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDataWithNilObject {
    XCTAssertNil([SAJSONUtil dataWithJSONObject:nil]);
}

- (void)testDataWithNullObject {
    XCTAssertNil([SAJSONUtil dataWithJSONObject:[NSNull null]]);
}

- (void)testDataWithEmptyStringObject {
    XCTAssertNil([SAJSONUtil dataWithJSONObject:@""]);
}

- (void)testDataWithNotEmptyStringObject {
    XCTAssertNil([SAJSONUtil dataWithJSONObject:@"ABC"]);
}

- (void)testDataWithIntegerNumberObject {
    XCTAssertNil([SAJSONUtil dataWithJSONObject:@12345]);
}

- (void)testDataWithFloatNumberObject {
    XCTAssertNil([SAJSONUtil dataWithJSONObject:@12345.123]);
}

- (void)testDataWithArrayObject {
    NSArray *array = [NSArray arrayWithObjects:@"A", @"B", @"C", nil];
    XCTAssertNotNil([SAJSONUtil dataWithJSONObject:array]);
}

- (void)testDataWithSetObject {
    NSSet *set = [NSSet setWithObjects:@"A", @"B", @"C", nil];
    XCTAssertNotNil([SAJSONUtil dataWithJSONObject:set]);
}

- (void)testDataWithDictionaryObject {
    XCTAssertNotNil([SAJSONUtil dataWithJSONObject:@{@"A" : @"B"}]);
}

- (void)testDataWithDateObject {
    XCTAssertNil([SAJSONUtil dataWithJSONObject:[NSDate date]]);
}

- (void)testStringWithNilObject {
    XCTAssertNil([SAJSONUtil stringWithJSONObject:nil]);
}

- (void)testStringWithNullObject {
    XCTAssertNil([SAJSONUtil stringWithJSONObject:[NSNull null]]);
}

- (void)testStringWithEmptyStringObject {
    XCTAssertNil([SAJSONUtil stringWithJSONObject:@""]);
}

- (void)testStringWithNotEmptyStringObject {
    XCTAssertNil([SAJSONUtil stringWithJSONObject:@"ABC"]);
}

- (void)testStringWithIntegerNumberObject {
    XCTAssertNil([SAJSONUtil stringWithJSONObject:@12345]);
}

- (void)testStringWithFloatNumberObject {
    XCTAssertNil([SAJSONUtil stringWithJSONObject:@12345.123]);
}

- (void)testStringWithArrayObject {
    NSArray *array = [NSArray arrayWithObjects:@"A", @"B", @"C", nil];
    XCTAssertNotNil([SAJSONUtil stringWithJSONObject:array]);
}

- (void)testStringWithSetObject {
    NSSet *set = [NSSet setWithObjects:@"A", @"B", @"C", nil];
    XCTAssertNotNil([SAJSONUtil stringWithJSONObject:set]);
}

- (void)testStringWithDictionaryObject {
    XCTAssertNotNil([SAJSONUtil stringWithJSONObject:@{@"A" : @"B"}]);
}

- (void)testStringWithDateObject {
    XCTAssertNil([SAJSONUtil stringWithJSONObject:[NSDate date]]);
}

- (void)testJSONObjectWithNilData {
    XCTAssertNil([SAJSONUtil JSONObjectWithData:nil]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:nil options:NSJSONReadingMutableContainers]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:nil options:NSJSONReadingMutableLeaves]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:nil options:NSJSONReadingFragmentsAllowed]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:nil options:NSJSONReadingAllowFragments]);
    
    if (@available(iOS 15.0, *)) {
        XCTAssertNil([SAJSONUtil JSONObjectWithData:nil options:NSJSONReadingJSON5Allowed]);
        XCTAssertNil([SAJSONUtil JSONObjectWithData:nil options:NSJSONReadingTopLevelDictionaryAssumed]);
    }
}

- (void)testJSONObjectWithEmptyData {
    XCTAssertNil([SAJSONUtil JSONObjectWithData:[NSData data]]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:[NSData data] options:NSJSONReadingMutableContainers]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:[NSData data] options:NSJSONReadingMutableLeaves]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:[NSData data] options:NSJSONReadingFragmentsAllowed]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:[NSData data] options:NSJSONReadingAllowFragments]);
    
    if (@available(iOS 15.0, *)) {
        XCTAssertNil([SAJSONUtil JSONObjectWithData:[NSData data] options:NSJSONReadingJSON5Allowed]);
        XCTAssertNil([SAJSONUtil JSONObjectWithData:[NSData data] options:NSJSONReadingTopLevelDictionaryAssumed]);
    }
}

- (void)testJSONObjectWithNotEmptyData {
    NSString *str = @"ABC";
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNil([SAJSONUtil JSONObjectWithData:data]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:data options:NSJSONReadingMutableContainers]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:data options:NSJSONReadingMutableLeaves]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed]);
    XCTAssertNil([SAJSONUtil JSONObjectWithData:data options:NSJSONReadingAllowFragments]);
    
    if (@available(iOS 15.0, *)) {
        XCTAssertNil([SAJSONUtil JSONObjectWithData:data options:NSJSONReadingJSON5Allowed]);
        XCTAssertNil([SAJSONUtil JSONObjectWithData:data options:NSJSONReadingTopLevelDictionaryAssumed]);
    }
}

- (void)testJSONObjectWithNilString {
    XCTAssertNil([SAJSONUtil JSONObjectWithString:nil]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:nil options:NSJSONReadingMutableContainers]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:nil options:NSJSONReadingMutableLeaves]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:nil options:NSJSONReadingFragmentsAllowed]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:nil options:NSJSONReadingAllowFragments]);
    
    if (@available(iOS 15.0, *)) {
        XCTAssertNil([SAJSONUtil JSONObjectWithString:nil options:NSJSONReadingJSON5Allowed]);
        XCTAssertNil([SAJSONUtil JSONObjectWithString:nil options:NSJSONReadingTopLevelDictionaryAssumed]);
    }
}

- (void)testJSONObjectWithEmptyString {
    XCTAssertNil([SAJSONUtil JSONObjectWithString:@""]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:@"" options:NSJSONReadingMutableContainers]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:@"" options:NSJSONReadingMutableLeaves]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:@"" options:NSJSONReadingFragmentsAllowed]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:@"" options:NSJSONReadingAllowFragments]);
    
    if (@available(iOS 15.0, *)) {
        XCTAssertNil([SAJSONUtil JSONObjectWithString:@"" options:NSJSONReadingJSON5Allowed]);
        XCTAssertNil([SAJSONUtil JSONObjectWithString:@"" options:NSJSONReadingTopLevelDictionaryAssumed]);
    }
}

- (void)testJSONObjectWithNotDictionaryString {
    XCTAssertNil([SAJSONUtil JSONObjectWithString:@"ABC"]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:@"ABC" options:NSJSONReadingMutableContainers]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:@"ABC" options:NSJSONReadingMutableLeaves]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:@"ABC" options:NSJSONReadingFragmentsAllowed]);
    XCTAssertNil([SAJSONUtil JSONObjectWithString:@"ABC" options:NSJSONReadingAllowFragments]);
    
    if (@available(iOS 15.0, *)) {
        XCTAssertNil([SAJSONUtil JSONObjectWithString:@"ABC" options:NSJSONReadingJSON5Allowed]);
        XCTAssertNil([SAJSONUtil JSONObjectWithString:@"ABC" options:NSJSONReadingTopLevelDictionaryAssumed]);
    }
}

- (void)testJSONObjectWithDictionaryString {
    NSDictionary *dic = @{@"A" : @"B"};
    NSError *err;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&err];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XCTAssertTrue([dic isEqualToDictionary:[SAJSONUtil JSONObjectWithString:str]]);
    XCTAssertTrue([dic isEqualToDictionary:[SAJSONUtil JSONObjectWithString:str options:NSJSONReadingMutableContainers]]);
    XCTAssertTrue([dic isEqualToDictionary:[SAJSONUtil JSONObjectWithString:str options:NSJSONReadingMutableLeaves]]);
    XCTAssertTrue([dic isEqualToDictionary:[SAJSONUtil JSONObjectWithString:str options:NSJSONReadingFragmentsAllowed]]);
    XCTAssertTrue([dic isEqualToDictionary:[SAJSONUtil JSONObjectWithString:str options:NSJSONReadingAllowFragments]]);
    
    if (@available(iOS 15.0, *)) {
        XCTAssertTrue([dic isEqualToDictionary:[SAJSONUtil JSONObjectWithString:str options:NSJSONReadingJSON5Allowed]]);
        XCTAssertTrue([dic isEqualToDictionary:[SAJSONUtil JSONObjectWithString:str options:NSJSONReadingTopLevelDictionaryAssumed]]);
    }
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
