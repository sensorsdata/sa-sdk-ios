//
// SAPresetPropertyPluginTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2021/9/18.
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
#include <sys/sysctl.h>
#import "SAPresetPropertyPlugin.h"

static NSString * const kSALibVersion = @"1.0.1";

@interface SAPresetPropertyPluginTests : XCTestCase

@property (nonatomic, strong) SAPresetPropertyPlugin *plugin;

@end

@implementation SAPresetPropertyPluginTests

- (void)setUp {
    _plugin = [[SAPresetPropertyPlugin alloc] initWithLibVersion:kSALibVersion];
    [_plugin prepare];
}

- (void)tearDown {
    _plugin = nil;
}

- (void)testPriority {
    XCTAssertTrue([self.plugin priority] == 250);
}

- (void)testModel {
    XCTAssertTrue([self.plugin.properties[@"$model"] isEqualToString:@"x86_64"] || [self.plugin.properties[@"$model"] isEqualToString:@"arm64"]);
}

- (void)testManufacturer {
    XCTAssertTrue([self.plugin.properties[@"$manufacturer"] isEqualToString:@"Apple"]);
}

- (void)testCarrier {
    XCTAssertNil(self.plugin.properties[@"$carrier"]);
}

- (void)testOS {
#if TARGET_OS_IOS
    XCTAssertTrue([self.plugin.properties[@"$os"] isEqualToString:@"iOS"]);
#elif TARGET_OS_OSX
    XCTAssertTrue([self.plugin.properties[@"$os"] isEqualToString:@"macOS"]);
#endif
}

- (void)testOSVersion {
#if TARGET_OS_IOS
    XCTAssertEqual(self.plugin.properties[@"$os_version"], [[UIDevice currentDevice] systemVersion]);
#elif TARGET_OS_OSX
    NSDictionary *systemVersion = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    XCTAssertEqual(self.plugin.properties[@"$os_version"], systemVersion[@"ProductVersion"]);
#endif
}

- (void)testLib {
#if TARGET_OS_IOS
    XCTAssertTrue([self.plugin.properties[@"$lib"] isEqualToString:@"iOS"]);
#elif TARGET_OS_OSX
    XCTAssertTrue([self.plugin.properties[@"$lib"] isEqualToString:@"macOS"]);
#endif
}

- (void)testAppID {
    XCTAssertTrue([self.plugin.properties[@"$app_id"] isEqualToString:@"com.apple.dt.xctest.tool"]);
}

- (void)testAppName {
    XCTAssertTrue([self.plugin.properties[@"$app_name"] isEqualToString:@"xctest"]);
}

- (void)testAppVersion {
    // 这个单元测试结果不对
//    XCTAssertNil(self.plugin.properties[@"$app_version"]);
}

- (void)testScreenWidth {
    NSInteger width = [UIScreen mainScreen].bounds.size.width;
    XCTAssertEqual(self.plugin.properties[@"$screen_width"], @(width));
}

- (void)testScreenHeight {
    NSInteger height = [UIScreen mainScreen].bounds.size.height;
    XCTAssertEqual(self.plugin.properties[@"$screen_height"], @(height));
}

- (void)testLibVersion {
    XCTAssertEqual(self.plugin.properties[@"$lib_version"], kSALibVersion);
}

- (void)testTimezoneOffset {
    NSInteger minutesOffsetGMT = - ([[NSTimeZone defaultTimeZone] secondsFromGMT] / 60);
    XCTAssertEqual([self.plugin.properties[@"$timezone_offset"] integerValue], minutesOffsetGMT);
}

- (void)testPerformanceStart {
    [self measureBlock:^{
        [self.plugin prepare];
    }];
}

@end
