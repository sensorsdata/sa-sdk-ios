//
// SADeviceIDPropertyPluginTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2022/1/11.
// Copyright © 2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SAIdentifier.h"
#import "SADeviceIDPropertyPlugin.h"

@interface SADeviceIDPropertyPluginTests : XCTestCase

@property (nonatomic, strong) SADeviceIDPropertyPlugin *plugin;

@end

@implementation SADeviceIDPropertyPluginTests

- (void)setUp {
    _plugin = [[SADeviceIDPropertyPlugin alloc] init];
    [_plugin prepare];
}

- (void)tearDown {
    _plugin = nil;
}


- (void)testPriority {
    XCTAssertTrue([self.plugin priority] == 1431656640);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
