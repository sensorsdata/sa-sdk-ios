//
// SALogMessageTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/20.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
