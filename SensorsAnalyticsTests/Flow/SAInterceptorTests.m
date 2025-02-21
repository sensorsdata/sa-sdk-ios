//
// SAInterceptorTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2022/4/20.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SAInterceptor.h"

@interface SAInterceptorTests : XCTestCase

@property (nonatomic, strong) SAFlowData *input;
@property (nonatomic, strong) SAInterceptor *interceptor;

@end

@implementation SAInterceptorTests

- (void)setUp {
    self.interceptor = [SAInterceptor interceptorWithParam:nil];
}

- (void)tearDown {
    self.interceptor = nil;
}

- (void)testUnimplementException {
    SAFlowData *input = [[SAFlowData alloc] init];
//    XCTAssertThrowsSpecificNamed([self.interceptor processWithInput:input completion:^(SAFlowData *output) {}], NSException, NSInternalInconsistencyException);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
