//
// SACoreResourcesTests.m
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
#import "SACoreResources.h"
#import "SensorsAnalyticsSDK.h"

// 默认不引入 SACoreResources+English 文件，需要在添加即可
//#import "SACoreResources+English.h"

@interface SACoreResourcesTests : XCTestCase

@property (nonatomic, strong) NSBundle *bundle;

@end

@implementation SACoreResourcesTests

- (void)setUp {
    _bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"SensorsAnalyticsSDKTest" ofType:@"bundle"]];
}

- (void)tearDown {
    _bundle = nil;
}

- (void)testAnalyticsFlows {
    NSString *jsonPath = [self.bundle pathForResource:@"sensors_analytics_flow.json" ofType:nil];
    NSArray *array = [SAJSONUtil JSONObjectWithData:[NSData dataWithContentsOfFile:jsonPath]];
    XCTAssertTrue([[SACoreResources analyticsFlows] isEqualToArray:array]);
}

- (void)testAnalyticsTasks {
    NSString *jsonPath = [self.bundle pathForResource:@"sensors_analytics_task.json" ofType:nil];
    NSArray *array = [SAJSONUtil JSONObjectWithData:[NSData dataWithContentsOfFile:jsonPath]];
    XCTAssertTrue([[SACoreResources analyticsTasks] isEqualToArray:array]);
}

- (void)testAnalyticsNodes {
    NSString *jsonPath = [self.bundle pathForResource:@"sensors_analytics_node.json" ofType:nil];
    NSArray *array = [SAJSONUtil JSONObjectWithData:[NSData dataWithContentsOfFile:jsonPath]];
    XCTAssertTrue([[SACoreResources analyticsNodes] isEqualToArray:array]);
}

- (void)testMCC {
    NSString *jsonPath = [self.bundle pathForResource:@"sa_mcc_mnc_mini.json" ofType:nil];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    NSDictionary *dicAllMcc = [SAJSONUtil JSONObjectWithData:jsonData];
    XCTAssertTrue([[SACoreResources mcc] isEqualToDictionary:dicAllMcc]);
}

- (void)testDefaultLanguageResources {
    // 获取语言资源的 Bundle
    NSBundle* languageBundle = nil;
    NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"SensorsAnalyticsSDKTest" ofType:@"bundle"]];
    NSString *path = [sensorsBundle pathForResource:@"zh-Hans" ofType:@"lproj"];
    if (path) {
        languageBundle = [NSBundle bundleWithPath:path];
    }

    NSString *localizablePath = [languageBundle pathForResource:@"Localizable" ofType:@"strings"];
    NSDictionary *localizedDict = [NSDictionary dictionaryWithContentsOfFile:localizablePath];

    XCTAssertTrue([[SACoreResources defaultLanguageResources] isEqualToDictionary:localizedDict]);
}

//- (void)testEnglishLanguageResources {
//    // 获取语言资源的 Bundle
//    NSBundle* languageBundle = nil;
//    NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"SensorsAnalyticsSDKTest" ofType:@"bundle"]];
//    NSString *path = [sensorsBundle pathForResource:@"en" ofType:@"lproj"];
//    if (path) {
//        languageBundle = [NSBundle bundleWithPath:path];
//    }
//
//    NSString *localizablePath = [languageBundle pathForResource:@"Localizable" ofType:@"strings"];
//    NSDictionary *localizedDict = [NSDictionary dictionaryWithContentsOfFile:localizablePath];
//
//    XCTAssertTrue([[SACoreResources englishLanguageResources] isEqualToDictionary:localizedDict]);
//}

@end
