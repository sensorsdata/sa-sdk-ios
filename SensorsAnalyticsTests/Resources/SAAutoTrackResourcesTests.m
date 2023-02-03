//
// SAAutoTrackResourcesTests.m
// SensorsAnalyticsTests
//
// Created by MC on 2023/1/17.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
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
#import "SAJSONUtil.h"
#import "SAAutoTrackResources.h"

@interface SAAutoTrackResourcesTests : XCTestCase

@property (nonatomic, strong) NSBundle *bundle;

@end

@implementation SAAutoTrackResourcesTests

- (void)setUp {
    _bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"SensorsAnalyticsSDKTest" ofType:@"bundle"]];
}

- (void)tearDown {
    _bundle = nil;
}

- (void)testGestureViewBlacklist {
    NSString *jsonPath = [self.bundle pathForResource:@"sa_autotrack_gestureview_blacklist.json" ofType:nil];
    NSDictionary *dic = [SAJSONUtil JSONObjectWithData:[NSData dataWithContentsOfFile:jsonPath]];
    XCTAssertTrue([[SAAutoTrackResources gestureViewBlacklist] isEqualToDictionary:dic]);
}

- (void)testViewControllerBlacklist {
    NSString *jsonPath = [self.bundle pathForResource:@"sa_autotrack_viewcontroller_blacklist.json" ofType:nil];
    NSDictionary *dic = [SAJSONUtil JSONObjectWithData:[NSData dataWithContentsOfFile:jsonPath]];
    XCTAssertTrue([[SAAutoTrackResources viewControllerBlacklist] isEqualToDictionary:dic]);
}

@end
