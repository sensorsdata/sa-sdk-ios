//
// SASerialQueueInterceptorTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2022/4/20.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SASerialQueueInterceptor.h"

@interface SASerialQueueInterceptorTests : XCTestCase

@property (nonatomic, strong) SAFlowData *input;
@property (nonatomic, strong) SASerialQueueInterceptor *interceptor;

@end

@implementation SASerialQueueInterceptorTests

- (void)setUp {
    self.input = [[SAFlowData alloc] init];
}

- (void)tearDown {
    self.input = nil;
    self.interceptor = nil;
}

- (void)testSync {
    self.interceptor = [SASerialQueueInterceptor interceptorWithParam:@{@"sync": @(YES)}];

    [self.interceptor processWithInput:self.input completion:^(SAFlowData * _Nonnull output) {
        NSString *label = [NSString stringWithUTF8String:dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];
        XCTAssertTrue([label hasPrefix:@"com.sensorsdata.serialQueue."]);
    }];
}

- (void)testAsync {
    self.interceptor = [SASerialQueueInterceptor interceptorWithParam:@{@"sync": @(NO)}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Serial Queue"];
    [self.interceptor processWithInput:self.input completion:^(SAFlowData * _Nonnull output) {
        NSString *label = [NSString stringWithUTF8String:dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];
        XCTAssertTrue([label hasPrefix:@"com.sensorsdata.serialQueue."]);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:0.5];
}

//- (void)testSameQueue {
//    self.interceptor = [SASerialQueueInterceptor interceptorWithParam:@{@"sync": @(NO)}];
//
//    XCTestExpectation *expectation = [self expectationWithDescription:@"Serial Queue"];
//    [self.interceptor processWithInput:self.input completion:^(SAFlowData * _Nonnull output) {
//        NSString *label = [NSString stringWithUTF8String:dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];
//        XCTAssertTrue([label hasPrefix:@"com.sensorsdata.serialQueue."]);
//        [expectation fulfill];
//    }];
//    [self waitForExpectations:@[expectation] timeout:0.5];
//}

@end
