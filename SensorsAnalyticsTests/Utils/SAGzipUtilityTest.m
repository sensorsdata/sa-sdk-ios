//
// SAGzipUtilityTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/9/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SAGzipUtility.h"

@interface SAGzipUtilityTest : XCTestCase

@end

@implementation SAGzipUtilityTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGzipDataWithEmptyData {
    XCTAssertNil([SAGzipUtility gzipData:[NSData data]]);
}

- (void)testGzipDataWithNilData {
    XCTAssertNil([SAGzipUtility gzipData:nil]);
}

- (void)testGzipDataWithJSONData {
//   NSDictionary *dic = @{@"AAA" : @"aaa"};
//   NSError *error = nil;
//   NSData *customData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
//   NSData *gzipData = [SAGzipUtility gzipData:customData];
//   XCTAssertTrue(gzipData.length > 0);
}

- (void)testGzipDataWithNotJSONData {
    NSData *customData = [@"NotJSONString" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNil([SAGzipUtility gzipData:customData]);
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
