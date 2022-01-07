//
// SAPresetPropertyTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2020/5/15.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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
#import "SAPresetProperty.h"
#import "SAConstants+Private.h"
#import "SAConfigOptions.h"
#import "SensorsAnalyticsSDK.h"

@interface SAPresetPropertyTest : XCTestCase

@property (nonatomic, strong) SAPresetProperty *presetProperty;
@property (nonatomic, strong) dispatch_queue_t readWriteQueue;

@end

@implementation SAPresetPropertyTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0" launchOptions:nil];
    options.autoTrackEventType = SensorsAnalyticsEventTypeAppStart | SensorsAnalyticsEventTypeAppEnd | SensorsAnalyticsEventTypeAppClick | SensorsAnalyticsEventTypeAppViewScreen;
    [SensorsAnalyticsSDK startWithConfigOptions:options];

    NSString *label = [NSString stringWithFormat:@"sensorsdata.readWriteQueue.%p", self];
    self.readWriteQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
    self.presetProperty = [[SAPresetProperty alloc] initWithQueue:self.readWriteQueue libVersion:[[SensorsAnalyticsSDK sharedInstance] libVersion]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.presetProperty = nil;
}

- (void)testLibPropertiesWithLibMethodCode {
    NSDictionary *libProperties = [self.presetProperty libPropertiesWithLibMethod:kSALibMethodCode];
    NSString *libMethod = libProperties[@"$lib_method"];
    NSString *libVersion = libProperties[@"$lib_version"];
    NSString *lib = libProperties[@"$lib"];
    
    XCTAssertTrue(libProperties.count == 4);
    XCTAssertTrue([libMethod isEqualToString:kSALibMethodCode]);
    XCTAssertTrue([libVersion isEqualToString:[[SensorsAnalyticsSDK sharedInstance] libVersion]]);
    XCTAssertTrue([lib isEqualToString:@"iOS"]);
}

- (void)testLibPropertiesWithLibMethodAutoTrack {
    NSDictionary *libProperties = [self.presetProperty libPropertiesWithLibMethod:kSALibMethodAuto];
    NSString *libMethod = libProperties[@"$lib_method"];
    NSString *libVersion = libProperties[@"$lib_version"];
    NSString *lib = libProperties[@"$lib"];
    
    XCTAssertTrue(libProperties.count == 4);
    XCTAssertTrue([libMethod isEqualToString:kSALibMethodAuto]);
    XCTAssertTrue([libVersion isEqualToString:[[SensorsAnalyticsSDK sharedInstance] libVersion]]);
    XCTAssertTrue([lib isEqualToString:@"iOS"]);    
}

- (void)testCurrentPresetProperties {
    NSDictionary *currentPresetProperties = [self.presetProperty currentPresetProperties];
    
    XCTAssertTrue(currentPresetProperties.count == 16);
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
