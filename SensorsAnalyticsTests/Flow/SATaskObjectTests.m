//
// SATaskObjectTests.m
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
#import "SATaskObject.h"

static NSString * const kSATaskObjectTestsID = @"1";
static NSString * const kSATaskObjectTestsName = @"a";

@interface SATaskObjectTests : XCTestCase

@end

@implementation SATaskObjectTests

- (void)testInit {
    NSArray *nodes = @[[[SANodeObject alloc] initWithNodeID:kSATaskObjectTestsID name:kSATaskObjectTestsName interceptor:[SAInterceptor interceptorWithParam:nil]]];
    SATaskObject *object = [[SATaskObject alloc] initWithTaskID:kSATaskObjectTestsID name:kSATaskObjectTestsName nodes:nodes];
    XCTAssertTrue([object.taskID isEqualToString:kSATaskObjectTestsID]);
    XCTAssertTrue([object.name isEqualToString:kSATaskObjectTestsName]);
    XCTAssertTrue([object.nodes isEqual:nodes]);
}

- (void)testInitWithDictionaryNodeIDs {
    NSArray *nodes = @[kSATaskObjectTestsID];
    NSDictionary *dic = @{@"id": kSATaskObjectTestsID, @"name": kSATaskObjectTestsName, @"nodes": nodes};
    SATaskObject *object = [[SATaskObject alloc] initWithDictionary:dic];
    XCTAssertTrue([object.taskID isEqualToString:kSATaskObjectTestsID]);
    XCTAssertTrue([object.name isEqualToString:kSATaskObjectTestsName]);
    XCTAssertTrue([object.nodeIDs isEqualToArray:nodes]);
    XCTAssertNil(object.nodes);
}

- (void)testLoadBundle {
    NSBundle *bundle = [NSBundle bundleForClass:[SATaskObjectTests class]];
    NSDictionary *result = [SATaskObject loadFromBundle:bundle];
    SATaskObject *object1 = result[kSATaskObjectTestsID];
    XCTAssertNotNil(object1);
    XCTAssertTrue(object1.nodeIDs.count == 3);
    XCTAssertNil(object1.nodes);

    SATaskObject *object2 = result[@"2"];
    XCTAssertNotNil(object2);
    XCTAssertTrue(object2.nodes.count == 3);
    XCTAssertNil(object2.nodeIDs);

}

@end
