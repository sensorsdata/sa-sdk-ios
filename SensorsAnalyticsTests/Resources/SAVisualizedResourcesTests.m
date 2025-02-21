//
// SAVisualizedResourcesTests.m
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
#import "SAVisualizedResources.h"

@interface SAVisualizedResourcesTests : XCTestCase

@property (nonatomic, strong) NSBundle *bundle;

@end

@implementation SAVisualizedResourcesTests

- (void)setUp {
    _bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"SensorsAnalyticsSDKTest" ofType:@"bundle"]];
}

- (void)tearDown {
    _bundle = nil;
}

- (void)testGestureViewBlacklist {
    NSString *jsonPath = [self.bundle pathForResource:@"sa_visualized_path.json" ofType:nil];
    NSDictionary *dic = [SAJSONUtil JSONObjectWithData:[NSData dataWithContentsOfFile:jsonPath]];

    NSString *visualizedPath = [SAVisualizedResources visualizedPath];
    NSDictionary *visualizedDic = [SAJSONUtil JSONObjectWithData:[visualizedPath dataUsingEncoding:NSUTF8StringEncoding]];

    XCTAssertTrue([visualizedDic isEqualToDictionary:dic]);
}

@end
