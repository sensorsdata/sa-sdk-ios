//
// SAURLUtilsTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/9/30.
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
#import "SAURLUtils.h"

@interface SAURLUtilsTest : XCTestCase

@end

@implementation SAURLUtilsTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testHostWithNilURL {
    XCTAssertNil([SAURLUtils hostWithURL:nil]);
}

- (void)testHostWithEmptyURL {
    XCTAssertNil([SAURLUtils hostWithURL:[[NSURL alloc] init]]);
}

- (void)testHostWithFileURL {
    NSURL *url = [NSURL fileURLWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"JSCallOC.html"]];
    XCTAssertTrue([[SAURLUtils hostWithURL:url] isEqualToString:@""]);
}

- (void)testHostWithNoHostURL {
    NSURL *url = [NSURL URLWithString:@"https:www"];
    XCTAssertNil([SAURLUtils hostWithURL:url]);
}

- (void)testHostWithHostURL {
    NSString *host = [SAURLUtils hostWithURL:[NSURL URLWithString:@"https://www.sensorsdata.cn/auto"]];
    XCTAssertTrue([host isEqualToString:@"www.sensorsdata.cn"]);
}

- (void)testHostWithNilURLString {
    XCTAssertNil([SAURLUtils hostWithURLString:nil]);
}

- (void)testHostWithEmptyURLString {
    XCTAssertNil([SAURLUtils hostWithURLString:@""]);
}

- (void)testHostWithFilePathString {
    NSString *str = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"JSCallOC.html"];
    XCTAssertNil([SAURLUtils hostWithURLString:str]);
}

- (void)testHostWithNoHostString {
    XCTAssertNil([SAURLUtils hostWithURLString:@"https:www"]);
}

- (void)testHostWithHostString {
    NSString *host = [SAURLUtils hostWithURLString:@"https://www.sensorsdata.cn/auto"];
    XCTAssertTrue([host isEqualToString:@"www.sensorsdata.cn"]);
}

- (void)testQueryItemsWithNilURL {
    XCTAssertNil([SAURLUtils queryItemsWithURL:nil]);
}

- (void)testQueryItemsWithEmptyURL {
    NSURL *url = [[NSURL alloc] init];
    XCTAssertTrue([SAURLUtils queryItemsWithURL:url].count == 0);
}

- (void)testQueryItemsWithFileURL {
    NSURL *url = [NSURL fileURLWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"JSCallOC.html"]];
    XCTAssertTrue([SAURLUtils queryItemsWithURL:url].count == 0);
}

- (void)testQueryItemsWithNoItemURL {
    NSURL *url = [NSURL URLWithString:@"https://www.sensorsdata.cn/auto"];
    XCTAssertTrue([SAURLUtils queryItemsWithURL:url].count == 0);
}

- (void)testQueryItemsWithItemURL {
    NSURL *url = [NSURL URLWithString:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0"];
    NSDictionary *items = @{@"project" : @"default", @"token" : @"95c73ae661f85aa0"};
    XCTAssertTrue([[SAURLUtils queryItemsWithURL:url] isEqualToDictionary:items]);
}

- (void)testQueryItemsWithNilURLString {
    XCTAssertNil([SAURLUtils queryItemsWithURLString:nil]);
}

- (void)testQueryItemsWithEmptyURLString {
    XCTAssertNil([SAURLUtils queryItemsWithURLString:@""]);
}

- (void)testQueryItemsWithFilePathString {
    NSString *str = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"JSCallOC.html"];
    XCTAssertTrue([SAURLUtils queryItemsWithURLString:str].count == 0);
}

- (void)testQueryItemsWithNoItemString {
    XCTAssertTrue([SAURLUtils queryItemsWithURLString:@"https://www.sensorsdata.cn/auto"].count == 0);
}

- (void)testQueryItemsWithItemString {
    NSString *str = @"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0";
    NSDictionary *items = @{@"project" : @"default", @"token" : @"95c73ae661f85aa0"};
    XCTAssertTrue([[SAURLUtils queryItemsWithURLString:str] isEqualToDictionary:items]);
}

- (void)testURLQueryStringWithNilParams {
    XCTAssertNil([SAURLUtils urlQueryStringWithParams:nil]);
}

- (void)testURLQueryStringWithEmptyParams {
    XCTAssertNil([SAURLUtils urlQueryStringWithParams:[NSDictionary dictionary]]);
}

- (void)testURLQueryStringWithDicParams {
    NSDictionary *params = @{@"v" : @"1.1.1",
                             @"nv" : @"2.2.2",
                             @"app_id" : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"],
                             @"project" : @"default"
    };
    NSString *urlQueryString = @"project=default&app_id=com.apple.dt.xctest.tool&v=1.1.1&nv=2.2.2";
    XCTAssertTrue([[SAURLUtils urlQueryStringWithParams:params] isEqualToString:urlQueryString]);
}

- (void)testURLQueryStringWithMDicParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"v"] = @"1.1.1";
    params[@"nv"] = @"2.2.2";
    params[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    params[@"project"] = @"default";

    NSString *urlQueryString = @"project=default&app_id=com.apple.dt.xctest.tool&v=1.1.1&nv=2.2.2";
    XCTAssertTrue([[SAURLUtils urlQueryStringWithParams:params] isEqualToString:urlQueryString]);
}

- (void)testDecodeQueryItemsWithNilURL {
    XCTAssertNil([SAURLUtils decodeQueryItemsWithURL:nil]);
}

- (void)testDecodeQueryItemsWithEmptyURL {
    XCTAssertNil([SAURLUtils decodeQueryItemsWithURL:[[NSURL alloc] init]]);
}

- (void)testDecodeQueryItemsWithURL {
    NSURL *url = [NSURL URLWithString:@"https:www"];
    XCTAssertNil([SAURLUtils decodeQueryItemsWithURL:url]);
}

- (void)testDecodeQueryItemsWithNoItemURL {
    NSURL *url = [NSURL URLWithString:@"https://www.sensorsdata.cn/auto"];
    XCTAssertNil([SAURLUtils decodeQueryItemsWithURL:url]);
}

- (void)testDecodeQueryItemsWithItemURL {
    NSURL *url = [NSURL URLWithString:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0"];
    NSDictionary *items = @{@"project" : @"default", @"token" : @"95c73ae661f85aa0"};
    XCTAssertTrue([[SAURLUtils decodeQueryItemsWithURL:url] isEqualToDictionary:items]);
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
