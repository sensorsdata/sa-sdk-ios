//
// SANodeObjectTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2022/4/15.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SANodeObject.h"

static NSString * const kSANodeObjectTestsID = @"123";
static NSString * const kSANodeObjectTestsName = @"abc";

@interface SANodeObjectTests : XCTestCase


@end

@implementation SANodeObjectTests

- (void)testInit {
    SAInterceptor *interceptor = [SAInterceptor interceptorWithParam:@{@"name": @"sensors_data"}];
    SANodeObject *object = [[SANodeObject alloc] initWithNodeID:kSANodeObjectTestsID name:kSANodeObjectTestsName interceptor:interceptor];
    XCTAssertTrue([object.nodeID isEqualToString:kSANodeObjectTestsID]);
    XCTAssertTrue([object.name isEqualToString:kSANodeObjectTestsName]);
    XCTAssertTrue(object.interceptor == interceptor);
}

- (void)testInitWithDictionary {
    NSDictionary *dic = @{@"id": kSANodeObjectTestsID, @"name": kSANodeObjectTestsName, @"interceptor": @"SAInterceptor", @"param": @{@"name": @"sensors_data"}};
    SANodeObject *object = [[SANodeObject alloc] initWithDictionary:dic];
    XCTAssertTrue([object.nodeID isEqualToString:kSANodeObjectTestsID]);
    XCTAssertTrue([object.name isEqualToString:kSANodeObjectTestsName]);
    XCTAssertNotNil(object.interceptor);
}

- (void)testLoadBundle {
    NSBundle *bundle = [NSBundle bundleForClass:[SANodeObjectTests class]];
    NSDictionary *result = [SANodeObject loadFromBundle:bundle];
    XCTAssertTrue(result.count == 3);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
