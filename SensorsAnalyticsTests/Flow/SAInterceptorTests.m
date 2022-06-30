//
// SAInterceptorTests.m
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
