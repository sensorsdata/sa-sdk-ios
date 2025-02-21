//
// SAAutoTrackResourcesTests.m
// SensorsAnalyticsTests
//
// Created by MC on 2023/1/17.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
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
