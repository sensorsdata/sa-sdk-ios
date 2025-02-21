//
// SAFlowObjectTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2022/4/15.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SAFlowObject.h"

static NSString * const kSAFlowObjectTestsID = @"1";
static NSString * const kSAFlowObjectTestsName = @"a";

@interface SAFlowObjectTests : XCTestCase

@end

@implementation SAFlowObjectTests

- (void)testInit {
    NSArray *tasks = @[];
    SAFlowObject *object = [[SAFlowObject alloc] initWithFlowID:kSAFlowObjectTestsID name:kSAFlowObjectTestsName tasks:tasks];
    XCTAssertTrue([object.flowID isEqualToString:kSAFlowObjectTestsID]);
    XCTAssertTrue([object.name isEqualToString:kSAFlowObjectTestsName]);
    XCTAssertTrue(object.tasks == tasks);
}

- (void)testInitWithDictionaryTaskIDs {
    NSArray *tasks = @[kSAFlowObjectTestsID];
    NSDictionary *dic = @{@"id": kSAFlowObjectTestsID, @"name": kSAFlowObjectTestsName, @"tasks": tasks};
    SAFlowObject *object = [[SAFlowObject alloc] initWithDictionary:dic];
    XCTAssertTrue([object.flowID isEqualToString:kSAFlowObjectTestsID]);
    XCTAssertTrue([object.name isEqualToString:kSAFlowObjectTestsName]);
    XCTAssertTrue([object.taskIDs isEqualToArray:tasks]);
    XCTAssertNil(object.tasks);
}

- (void)testInitWithDictionaryTasks {
    NSBundle *bundle = [NSBundle bundleForClass:[SAFlowObjectTests class]];
    NSDictionary *result = [SATaskObject loadFromBundle:bundle];
    NSArray *tasks = result.allValues;
    NSDictionary *dic = @{@"id": kSAFlowObjectTestsID, @"name": kSAFlowObjectTestsName, @"tasks": tasks};
    SAFlowObject *object = [[SAFlowObject alloc] initWithDictionary:dic];
    XCTAssertTrue([object.flowID isEqualToString:kSAFlowObjectTestsID]);
    XCTAssertTrue([object.name isEqualToString:kSAFlowObjectTestsName]);
//    XCTAssertTrue(object.tasks );
    XCTAssertNotNil(object.taskIDs);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
