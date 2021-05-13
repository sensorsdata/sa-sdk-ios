//
// SAAppLifecycleUtilsTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/4/22.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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
#import "SAAppLifecycle.h"

@interface SAAppLifecycleUtilsTest : XCTestCase

@property (nonatomic, strong) SAAppLifecycle *appLifecycle;

@end

@implementation SAAppLifecycleUtilsTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.appLifecycle = [[SAAppLifecycle alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.appLifecycle = nil;
}

- (void)testWillEnterForeground {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    XCTAssertEqual(self.appLifecycle.state, SAAppLifecycleStateInit);
}

- (void)testDidBecomeActive {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    XCTAssertEqual(self.appLifecycle.state, SAAppLifecycleStateStart);
}

- (void)testWillResignActive {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:nil];
    XCTAssertEqual(self.appLifecycle.state, SAAppLifecycleStateInit);
}

- (void)testDidEnterBackground {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    XCTAssertEqual(self.appLifecycle.state, SAAppLifecycleStateEnd);
}

- (void)testWillTerminate {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification object:nil];
    XCTAssertEqual(self.appLifecycle.state, SAAppLifecycleStateTerminate);
}

- (void)testDidFinishLaunching {
    if (@available(iOS 13.0, *)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
        XCTAssertEqual(self.appLifecycle.state, SAAppLifecycleStateInit);
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
        XCTAssertEqual(self.appLifecycle.state, SAAppLifecycleStateStart);
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
