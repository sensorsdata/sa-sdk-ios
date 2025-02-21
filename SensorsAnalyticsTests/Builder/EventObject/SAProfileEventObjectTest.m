//
// SAProfileEventObjectTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/25.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SAProfileEventObject.h"
#import "SensorsAnalyticsSDK.h"

@interface SAProfileEventObjectTest : XCTestCase

@end

@implementation SAProfileEventObjectTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0" launchOptions:nil];
    options.autoTrackEventType = SensorsAnalyticsEventTypeAppStart | SensorsAnalyticsEventTypeAppEnd | SensorsAnalyticsEventTypeAppClick | SensorsAnalyticsEventTypeAppViewScreen;
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testEventObjectWithEmptyType {
    SAProfileEventObject *object = [[SAProfileEventObject alloc] initWithType:@""];
    XCTAssert(object.type & SAEventTypeDefault);
}

- (void)testEventObjectWithNilType {
    NSString *type = nil;
    SAProfileEventObject *object = [[SAProfileEventObject alloc] initWithType:type];
    XCTAssert(object.type & SAEventTypeDefault);
}

- (void)testEventObjectWithNotStringType {
//   NSString *type = (NSString *)@{@"A" : @"B"};
//   SAProfileEventObject *object = [[SAProfileEventObject alloc] initWithType:type];
//   XCTAssertNil(object.type);
}

- (void)testEventObjectWithStringType {
    SAProfileEventObject *object = [[SAProfileEventObject alloc] initWithType:@"ABC"];
    XCTAssert(object.type & SAEventTypeDefault);
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
