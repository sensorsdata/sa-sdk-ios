//
// SANetworkTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/26.
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
#import "SANetwork.h"
#import "SensorsAnalyticsSDK.h"

@interface SANetworkTest : XCTestCase

@property (nonatomic, strong) SANetwork *network;

@end

@implementation SANetworkTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0" launchOptions:nil];
    options.autoTrackEventType = SensorsAnalyticsEventTypeAppStart | SensorsAnalyticsEventTypeAppEnd | SensorsAnalyticsEventTypeAppClick | SensorsAnalyticsEventTypeAppViewScreen;
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testEncodeCookie {
    SANetwork *network = [[SANetwork alloc] init];
    [network setCookie:@"ABC哈😄%a%b%c" isEncoded:YES];
    XCTAssertTrue([[network cookieWithDecoded:YES] isEqualToString:@"ABC哈😄%a%b%c"]);
    XCTAssertFalse([[network cookieWithDecoded:NO] isEqualToString:@"ABC哈😄%a%b%c"]);
}

- (void)testNotEncodeCookie {
    SANetwork *network = [[SANetwork alloc] init];
    [network setCookie:@"ABC哈😄%a%b%c" isEncoded:NO];
    XCTAssertTrue([[network cookieWithDecoded:NO] isEqualToString:@"ABC哈😄%a%b%c"]);
    XCTAssertFalse([[network cookieWithDecoded:YES] isEqualToString:@"ABC哈😄%a%b%c"]);
}

- (void)testServerURL {
    SANetwork *network = [[SANetwork alloc] init];
    XCTAssertTrue([network.serverURL.absoluteString isEqualToString:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0"]);
}

- (void)testHost {
    SANetwork *network = [[SANetwork alloc] init];
    XCTAssertTrue([network.host isEqualToString:@"sdk-test.cloud.sensorsdata.cn"]);
}

- (void)testProject {
    SANetwork *network = [[SANetwork alloc] init];
    XCTAssertTrue([network.project isEqualToString:@"default"]);
}

- (void)testToken {
    SANetwork *network = [[SANetwork alloc] init];
    XCTAssertTrue([network.token isEqualToString:@"95c73ae661f85aa0"]);
}

- (void)testBaseURLComponents {
    SANetwork *network = [[SANetwork alloc] init];
    XCTAssertTrue([network.baseURLComponents.scheme isEqualToString:@"http"]);
    XCTAssertTrue([network.baseURLComponents.host isEqualToString:@"sdk-test.cloud.sensorsdata.cn"]);
    XCTAssertTrue([network.baseURLComponents.port isEqualToNumber:@8006]);
    XCTAssertTrue([network.baseURLComponents.query isEqualToString:@"project=default&token=95c73ae661f85aa0"]);
}

- (void)testValidServerURL {
    SANetwork *network = [[SANetwork alloc] init];
    XCTAssertTrue([network isValidServerURL]);
}

- (void)testSameProjectWithEmptyURL {
    SANetwork *network = [[SANetwork alloc] init];
    XCTAssertFalse([network isSameProjectWithURLString:@""]);
}

- (void)testSameProjectWithNilURL {
    SANetwork *network = [[SANetwork alloc] init];
    NSString *urlString = nil;
    XCTAssertFalse([network isSameProjectWithURLString:urlString]);
}

- (void)testSameProjectWithNotStringURL {
//    SANetwork *network = [[SANetwork alloc] init];
//    NSString *urlString = (NSString *)@{@"A" : @"a"};
//    XCTAssertFalse([network isSameProjectWithURLString:urlString]);
}

- (void)testSameProjectWithNotValidStringURL {
    SANetwork *network = [[SANetwork alloc] init];
    BOOL isSameProject = [network isSameProjectWithURLString:@".sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0"];
    XCTAssertFalse(isSameProject);
}

- (void)testSameProjectWithSameStringURL {
    SANetwork *network = [[SANetwork alloc] init];
    BOOL isSameProject = [network isSameProjectWithURLString:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0"];
    XCTAssertTrue(isSameProject);
}

- (void)testSameProjectWithDifferentStringURL {
    SANetwork *network = [[SANetwork alloc] init];
    BOOL isDifferentProject = ![network isSameProjectWithURLString:@"http://sdk.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0"];
    XCTAssertTrue(isDifferentProject);
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
