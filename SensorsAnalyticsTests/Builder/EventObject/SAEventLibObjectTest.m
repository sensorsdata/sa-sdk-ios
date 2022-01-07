//
// SAEventLibObjectTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/22.
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
#import "SABaseEventObject.h"
#import "SensorsAnalyticsSDK.h"

@interface SAEventLibObjectTest : XCTestCase

@end

@implementation SAEventLibObjectTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0" launchOptions:nil];
    options.autoTrackEventType = SensorsAnalyticsEventTypeAppStart | SensorsAnalyticsEventTypeAppEnd | SensorsAnalyticsEventTypeAppClick | SensorsAnalyticsEventTypeAppViewScreen;
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testJsonObjectWithEmptyMethod {
    SAEventLibObject *libObject = [[SAEventLibObject alloc] init];
    libObject.method = @"";
    NSDictionary *jsonObject = [libObject jsonObject];
    XCTAssertTrue([jsonObject[@"$lib"] isEqualToString:@"iOS"]);
    XCTAssertTrue([jsonObject[@"$lib_method"] isEqualToString:@"code"]);
    XCTAssertTrue([jsonObject[@"$lib_version"] isEqualToString:[SensorsAnalyticsSDK.sharedInstance libVersion]]);
    XCTAssertNil(jsonObject[@"$lib_detail"]);
}

- (void)testJsonObjectWithNilMethod {
    SAEventLibObject *libObject = [[SAEventLibObject alloc] init];
    NSString *method = nil;
    libObject.method = method;
    NSDictionary *jsonObject = [libObject jsonObject];
    XCTAssertTrue([jsonObject[@"$lib"] isEqualToString:@"iOS"]);
    XCTAssertTrue([jsonObject[@"$lib_method"] isEqualToString:@"code"]);
    XCTAssertTrue([jsonObject[@"$lib_version"] isEqualToString:[SensorsAnalyticsSDK.sharedInstance libVersion]]);
    XCTAssertNil(jsonObject[@"$lib_detail"]);
}

- (void)testJsonObjectWithNotStringMethod {
    SAEventLibObject *libObject = [[SAEventLibObject alloc] init];
    NSString *method = (NSString *)@{@"A" : @"B"};
    libObject.method = method;
    NSDictionary *jsonObject = [libObject jsonObject];
    XCTAssertTrue([jsonObject[@"$lib"] isEqualToString:@"iOS"]);
    XCTAssertTrue([jsonObject[@"$lib_method"] isEqualToString:@"code"]);
    XCTAssertTrue([jsonObject[@"$lib_version"] isEqualToString:[SensorsAnalyticsSDK.sharedInstance libVersion]]);
    XCTAssertNil(jsonObject[@"$lib_detail"]);
}

- (void)testJsonObjectWithStringMethod {
    SAEventLibObject *libObject = [[SAEventLibObject alloc] init];
    libObject.method = @"A";
    NSDictionary *jsonObject = [libObject jsonObject];
    XCTAssertTrue([jsonObject[@"$lib"] isEqualToString:@"iOS"]);
    XCTAssertTrue([jsonObject[@"$lib_method"] isEqualToString:@"A"]);
    XCTAssertTrue([jsonObject[@"$lib_version"] isEqualToString:[SensorsAnalyticsSDK.sharedInstance libVersion]]);
    XCTAssertNil(jsonObject[@"$lib_detail"]);
}

- (void)testJsonObjectWithEmptyLib {
    SAEventLibObject *libObject = [[SAEventLibObject alloc] init];
    libObject.detail = @"";
    NSDictionary *jsonObject = [libObject jsonObject];
    XCTAssertTrue([jsonObject[@"$lib"] isEqualToString:@"iOS"]);
    XCTAssertTrue([jsonObject[@"$lib_method"] isEqualToString:@"code"]);
    XCTAssertTrue([jsonObject[@"$lib_version"] isEqualToString:[SensorsAnalyticsSDK.sharedInstance libVersion]]);
    XCTAssertTrue([jsonObject[@"$lib_detail"] isEqualToString:@""]);
}

- (void)testJsonObjectWithNilDetail {
    SAEventLibObject *libObject = [[SAEventLibObject alloc] init];
    libObject.detail = nil;
    NSDictionary *jsonObject = [libObject jsonObject];
    XCTAssertTrue([jsonObject[@"$lib"] isEqualToString:@"iOS"]);
    XCTAssertTrue([jsonObject[@"$lib_method"] isEqualToString:@"code"]);
    XCTAssertTrue([jsonObject[@"$lib_version"] isEqualToString:[SensorsAnalyticsSDK.sharedInstance libVersion]]);
    XCTAssertNil(jsonObject[@"$lib_detail"]);
}

- (void)testJsonObjectWithNotStringDetail {
    SAEventLibObject *libObject = [[SAEventLibObject alloc] init];
    libObject.detail = (NSString *)@{@"A" : @"B"};
    NSDictionary *jsonObject = [libObject jsonObject];
    XCTAssertTrue([jsonObject[@"$lib"] isEqualToString:@"iOS"]);
    XCTAssertTrue([jsonObject[@"$lib_method"] isEqualToString:@"code"]);
    XCTAssertTrue([jsonObject[@"$lib_version"] isEqualToString:[SensorsAnalyticsSDK.sharedInstance libVersion]]);
    XCTAssertTrue([jsonObject[@"$lib_detail"] isEqualToDictionary:@{@"A" : @"B"}]);
}

- (void)testJsonObjectWithStringDetail {
    SAEventLibObject *libObject = [[SAEventLibObject alloc] init];
    libObject.detail = @"A";
    NSDictionary *jsonObject = [libObject jsonObject];
    XCTAssertTrue([jsonObject[@"$lib"] isEqualToString:@"iOS"]);
    XCTAssertTrue([jsonObject[@"$lib_method"] isEqualToString:@"code"]);
    XCTAssertTrue([jsonObject[@"$lib_version"] isEqualToString:[SensorsAnalyticsSDK.sharedInstance libVersion]]);
    XCTAssertTrue([jsonObject[@"$lib_detail"] isEqualToString:@"A"]);
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
