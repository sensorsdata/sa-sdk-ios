//
// SAFlowObjectTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2022/4/15.
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
