//
// SATaskObjectTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2022/4/15.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
