//
// SAFlowManagerTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2022/4/20.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SAFlowManager.h"

@interface SAFlowManagerTests : XCTestCase

@property (nonatomic, strong) SAFlowManager *manager;

@end

@interface SAFlowManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, SANodeObject *> *nodes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, SATaskObject *> *tasks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, SAFlowObject *> *flows;

@end


@implementation SAFlowManagerTests

- (void)setUp {
    self.manager = [[SAFlowManager alloc] init];
    [self loadFlows];
}

- (void)loadFlows {
    NSBundle *bundle = [NSBundle bundleForClass:[SAFlowManager class]];
    [self.manager.nodes addEntriesFromDictionary:[SANodeObject loadFromBundle:bundle]];
    [self.manager.tasks addEntriesFromDictionary:[SATaskObject loadFromBundle:bundle]];
    [self.manager.flows addEntriesFromDictionary:[SAFlowObject loadFromBundle:bundle]];
}


- (void)tearDown {
    self.manager = nil;
}

- (void)testLoadFlows {
    NSString *objectID1 = @"1";

    SAFlowObject *object1 = [self.manager flowForID:objectID1];
    XCTAssertNotNil(object1);
    XCTAssertTrue([object1.flowID isEqualToString:objectID1]);
    XCTAssertTrue([object1.name isEqualToString:@"a"]);
    XCTAssertTrue(object1.tasks.count == 0);
    XCTAssertTrue(object1.taskIDs.count == 2);
    XCTAssertTrue([object1.taskIDs[0] isEqualToString:@"1"]);
    XCTAssertTrue([object1.taskIDs[1] isEqualToString:@"2"]);
    XCTAssertTrue([object1.param[@"name"] isEqualToString:@"123"]);

    NSString *objectID2 = @"2";

    SAFlowObject *object2 = [self.manager flowForID:objectID2];
    XCTAssertNotNil(object2);
    XCTAssertTrue([object2.flowID isEqualToString:objectID2]);
    XCTAssertTrue([object2.name isEqualToString:@"b"]);
    XCTAssertTrue(object2.taskIDs.count == 0);
    XCTAssertTrue(object2.tasks.count == 2);
    XCTAssertTrue([object2.tasks.firstObject.taskID isEqualToString:@"1"]);
    XCTAssertTrue([object2.tasks.lastObject.taskID isEqualToString:@"2"]);
    XCTAssertNil(object2.param);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
