//
// SAPhonePresetPropertyTest.m
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

@interface SAPresetPropertyObject ()

- (NSString *)sysctlByName:(NSString *)name;

@end

@interface SAPhonePresetPropertyTest : XCTestCase

@property (nonatomic, strong) SAPhonePresetProperty *property;

@end

@implementation SAPhonePresetPropertyTest

- (void)setUp {
    _property = [[SAPhonePresetProperty alloc] init];
}

- (void)tearDown {
    _property = nil;
}

- (void)testOS {
    NSString *os = @"iOS";
    XCTAssertTrue([_property.properties[@"$os"] isEqualToString:os]);
}

- (void)testOSVersion {
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    XCTAssertTrue([_property.properties[@"$os_version"] isEqualToString:osVersion]);
}

- (void)testDeviceModel {
    NSString *model = [_property sysctlByName:@"hw.machine"];
    XCTAssertTrue([_property.properties[@"$model"] isEqualToString:model]);
}

- (void)testLib {
    NSString *lib = @"iOS";
    XCTAssertTrue([_property.properties[@"$lib"] isEqualToString:lib]);
}

- (void)testScreenHeight {
    NSInteger height = UIScreen.mainScreen.bounds.size.height;
    XCTAssertEqual(_property.properties[@"$screen_height"], @(height));
}

- (void)testScreenWidth {
    NSInteger width = UIScreen.mainScreen.bounds.size.width;
    XCTAssertEqual(_property.properties[@"$screen_width"], @(width));
}

- (void)testCarrier {
    XCTAssertNil(_property.properties[@"$carrier"]);
}

- (void)testPerformanceProperties {
    [self measureBlock:^{
        [_property properties];
    }];
}

@end
