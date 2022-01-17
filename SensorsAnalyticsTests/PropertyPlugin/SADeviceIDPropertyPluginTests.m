//
// SADeviceIDPropertyPluginTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2022/1/11.
// Copyright © 2022 Sensors Data Co., Ltd. All rights reserved.
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
#import "SAIdentifier.h"
#import "SADeviceIDPropertyPlugin.h"

@interface SADeviceIDPropertyPluginTests : XCTestCase

@property (nonatomic, strong) SADeviceIDPropertyPlugin *plugin;

@end

@implementation SADeviceIDPropertyPluginTests

- (void)setUp {
    _plugin = [[SADeviceIDPropertyPlugin alloc] init];
    [_plugin start];
}

- (void)tearDown {
    _plugin = nil;
}


- (void)testPriority {
    XCTAssertTrue([self.plugin priority] == 1431656640);
}

- (void)testAnonymizationID {
    NSData *data = [[SAIdentifier hardwareID] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *anonymizationID = [data base64EncodedStringWithOptions:0];
    XCTAssertTrue([self.plugin.properties[@"$anonymization_id"] isEqualToString:anonymizationID]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
