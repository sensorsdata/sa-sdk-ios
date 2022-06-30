//
// SAEventValidateInterceptorTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2022/4/20.
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
#import "SAEventValidateInterceptor.h"
#import "SATrackEventObject.h"

@interface SAEventValidateInterceptorTests : XCTestCase

@property (nonatomic, strong) SAFlowData *input;
@property (nonatomic, strong) SAEventValidateInterceptor *interceptor;

@end

@implementation SAEventValidateInterceptorTests

- (void)setUp {
    self.input = [[SAFlowData alloc] init];
    self.interceptor = [SAEventValidateInterceptor interceptorWithParam:nil];
}

- (void)tearDown {
    self.input = nil;
    self.interceptor = nil;
}

- (void)testError {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@"123"];
    self.input.eventObject = object;

    [self.interceptor processWithInput:self.input completion:^(SAFlowData * _Nonnull output) {
        XCTAssertNotNil(output.message);
        XCTAssertTrue(output.state == SAFlowStateNext);
    }];
}

- (void)testNoError {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@"abc"];
    self.input.eventObject = object;

    [self.interceptor processWithInput:self.input completion:^(SAFlowData * _Nonnull output) {
        XCTAssertNil(output.message);
        XCTAssertTrue(output.state == SAFlowStateNext);
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
