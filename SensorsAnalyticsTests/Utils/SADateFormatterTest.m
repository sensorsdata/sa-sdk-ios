//
// SADateFormatterTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/9/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SADateFormatter.h"

@interface SADateFormatterTest : XCTestCase

@end

@implementation SADateFormatterTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDateFormatterWithEmptyString {
//   NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@""];
//   NSString *current = [dateFormatter stringFromDate:[NSDate date]];

}

- (void)testDateFormatterWithNilString {
//   NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:nil];
//   NSString *current = [dateFormatter stringFromDate:[NSDate date]];
}

- (void)testLocaleIdentifier {
    // 修复 iOS 15.4 中国大陆地区在 12 小时制格式化日期时包含 AM/PM 问题
    NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@""];
    XCTAssertTrue([dateFormatter.locale.localeIdentifier isEqualToString:@"en_US_POSIX"]);
}

- (void)testDateFormatter {
    NSString *formatter = @"yyyy-MM-dd HH:mm:ss";
    NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:formatter];
    XCTAssertTrue([dateFormatter.dateFormat isEqualToString:formatter]);
}

-(void)testDateFromString {
    NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = @"2022-03-21 18:07:09";
    XCTAssertNotNil([dateFormatter dateFromString:dateString]);
}

- (void)testDateFormatterWithNotDateFormatterString {
    NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"jjjj"];
    NSString *current = [dateFormatter stringFromDate:[NSDate date]];
    XCTAssertTrue([current isEqualToString:@""]);
}

- (void)testDateFormatterWithEventDateFormatterString {
    NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:kSAEventDateFormatter];
    NSString *current = [dateFormatter stringFromDate:[NSDate date]];
    XCTAssertTrue(current.length > 0);
}

- (void)testDateFormatterWithCustomDateFormatterString {
    NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
    NSString *current = [dateFormatter stringFromDate:[NSDate date]];
    XCTAssertTrue(current.length > 0);
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
