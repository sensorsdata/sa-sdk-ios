//
// SALogMessageTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/20.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SALogMessage.h"

@interface SALogMessageTest : XCTestCase

@end

@implementation SALogMessageTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testLogMessage {
    SALogMessage *logMessage = [[SALogMessage alloc] initWithMessage:@"testMessage"
                                                               level:SALogLevelInfo
                                                                file:@"testLogFile"
                                                            function:@"testLogFunction"
                                                                line:10
                                                             context:22
                                                           timestamp:[NSDate dateWithTimeIntervalSince1970:1000]];
    
    XCTAssertTrue([logMessage.message isEqualToString:@"testMessage"]);
    XCTAssertEqual(logMessage.level, SALogLevelInfo);
    XCTAssertTrue([logMessage.file isEqualToString:@"testLogFile"]);
    XCTAssertTrue([logMessage.fileName isEqualToString:@"testLogFile".lastPathComponent]);
    XCTAssertTrue([logMessage.function isEqualToString:@"testLogFunction"]);
    XCTAssertEqual(logMessage.line, 10);
    XCTAssertEqual(logMessage.context, 22);
    XCTAssertEqual(logMessage.timestamp, [NSDate dateWithTimeIntervalSince1970:1000]);
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
