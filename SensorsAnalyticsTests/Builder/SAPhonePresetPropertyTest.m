//
// SAPhonePresetPropertyTest.m
// SensorsAnalyticsTests
//
// Created by yuqiang on 2022/1/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

- (void)testPerformanceProperties {
    [self measureBlock:^{
        [_property properties];
    }];
}

@end
