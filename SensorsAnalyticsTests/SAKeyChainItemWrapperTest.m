//
// SAKeyChainItemWrapperTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/27.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SAKeyChainItemWrapper.h"

@interface SAKeyChainItemWrapperTest : XCTestCase

@end

@implementation SAKeyChainItemWrapperTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSaveUdidWithEmptyUdid {
//   XCTAssertTrue([[SAKeyChainItemWrapper saveUdid:@""] isEqualToString:@""]);
}

- (void)testSaveUdidWithNilUdid {
    XCTAssertNil([SAKeyChainItemWrapper saveUdid:nil]);
}

- (void)testSaveUdidWithNotStringUdid {
    NSString *udid = (NSString *)@[@1, @2];
    XCTAssertNil([SAKeyChainItemWrapper saveUdid:udid]);
}

- (void)testSaveUdidWithStringUdid {
//   XCTAssertTrue([[SAKeyChainItemWrapper saveUdid:@"ABC"] isEqualToString:@"ABC"]);
}

- (void)testSaveOrUpdatePassword {
//   XCTAssertTrue([SAKeyChainItemWrapper saveOrUpdatePassword:@"password" account:@"account" service:@"service" accessGroup:nil]);
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
