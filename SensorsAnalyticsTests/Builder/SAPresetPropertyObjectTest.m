//
// SAPresetPropertyObjectTest.m
// SensorsAnalyticsTests
//
// Created by yuqiang on 2022/1/18.
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
#import "SAPresetPropertyObject.h"

@interface SAPresetPropertyObjectTest : XCTestCase

@property (nonatomic, strong) SAPresetPropertyObject *property;

@end

@implementation SAPresetPropertyObjectTest

- (void)setUp {
    _property = [[SAPresetPropertyObject alloc] init];
}

- (void)tearDown {
    _property = nil;
}

- (void)testManufacturer {
    XCTAssertTrue([_property.properties[@"$manufacturer"] isEqualToString:@"Apple"]);
}

- (void)testOS {
    XCTAssertNil(_property.properties[@"$os"]);
}

- (void)testOSVersion {
    XCTAssertNil(_property.properties[@"$os_version"]);
}

- (void)testDeviceModel {
    XCTAssertNil(_property.properties[@"$model"]);
}

- (void)testLib {
    XCTAssertNil(_property.properties[@"$lib"]);
}

- (void)testScreenHeight {
    XCTAssertEqual(_property.properties[@"$screen_height"], @((NSInteger)0));
}

- (void)testScreenWidth {
    XCTAssertEqual(_property.properties[@"$screen_width"], @((NSInteger)0));
}

- (void)testAppID {
    NSString *appID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    XCTAssertEqual(_property.properties[@"$app_id"], appID);
}

- (void)testAppName {
    NSString *displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!displayName) {
        displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
    if (!displayName) {
        displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];
    }
    XCTAssertEqual(_property.properties[@"$app_name"], displayName);
}

- (void)testTimezoneOffset {
    NSInteger minutesOffsetGMT = - ([[NSTimeZone defaultTimeZone] secondsFromGMT] / 60);
    XCTAssertEqual(_property.properties[@"$timezone_offset"], @(minutesOffsetGMT));
}

- (void)testPerformanceProperties {
    [self measureBlock:^{
        [_property properties];
    }];
}

@end
