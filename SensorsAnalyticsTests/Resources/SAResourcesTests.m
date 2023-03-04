//
// SAResourcesTests.m
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

@interface SAResourcesTests : XCTestCase

@end

@implementation SAResourcesTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (BOOL)isBoolNumber:(NSNumber *)num {
   CFTypeID boolID = CFBooleanGetTypeID(); // the type ID of CFBoolean
   CFTypeID numID = CFGetTypeID((__bridge CFTypeRef)(num)); // the type ID of num
   return numID == boolID;
}

- (NSString *)dictionaryCodeGeneratorWithDictionary:(NSDictionary *)dic {
    NSMutableString *code = [NSMutableString stringWithString:@"@{"];
    for (NSString *key in dic.allKeys) {
        id value = dic[key];
        if ([value isKindOfClass:[NSString class]]) {
            [code appendFormat:@"@\"%@\":@\"%@\",", key, value];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            if ([self isBoolNumber:value]) {
                [code appendFormat:@"@\"%@\":@(%@),", key, [value boolValue] ? @"YES" : @"NO"];
            } else {
                [code appendFormat:@"@\"%@\":@(%@),", key, value];
            }
        } else if ([value isKindOfClass:[NSNull class]]) {
            [code appendFormat:@"@\"%@\":[NSNull null],", key];
        } else if ([value isKindOfClass:[NSArray class]]) {
            [code appendFormat:@"@\"%@\":%@,", key, [self arrayCodeGeneratorWithArray:value]];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            [code appendFormat:@"@\"%@\":%@,", key, [self dictionaryCodeGeneratorWithDictionary:value]];
        }
    }
    [code appendString:@"}"];
    return code;
}

- (NSString *)arrayCodeGeneratorWithArray:(NSArray *)array {
    NSMutableString *code = [NSMutableString stringWithString:@"@["];
    for (id value in array) {
        if ([value isKindOfClass:[NSString class]]) {
            [code appendFormat:@"@\"%@\",", value];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            [code appendFormat:@"@(%@),", value];
        } else if ([value isKindOfClass:[NSArray class]]) {
            [code appendFormat:@"%@,", [self arrayCodeGeneratorWithArray:value]];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            [code appendFormat:@"%@,", [self dictionaryCodeGeneratorWithDictionary:value]];
        }
    }
    [code appendString:@"]"];
    return code;
}

- (NSString *)jsonToDictionaryCodeGeneratorWithFileName:(NSString *)fileName {
    NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"SensorsAnalyticsSDKTest" ofType:@"bundle"]];
    NSString *jsonPath = [sensorsBundle pathForResource:fileName ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    if (!jsonData) {
        return nil;
    }

    id info = [SAJSONUtil JSONObjectWithData:jsonData];
    if ([info isKindOfClass:[NSArray class]]) {
        return [self arrayCodeGeneratorWithArray:info];
    } else {
        return [self dictionaryCodeGeneratorWithDictionary:info];
    }
}

- (void)testDictionaryCodeGenerator {
    NSDictionary *dic = @{@"key": @"value"};
    NSString *json = [self dictionaryCodeGeneratorWithDictionary:dic];
    NSLog(@"Dictionary Code Generator Result: %@", json);
    XCTAssertTrue([json isEqualToString:@"@{@\"key\":@\"value\",}"]);
}

- (void)testJSONFileGestureViewBlacklist {
    NSString *json = [self jsonToDictionaryCodeGeneratorWithFileName:@"sa_autotrack_gestureview_blacklist"];
    NSLog(@"Code Generator Result: %@", json);
    XCTAssertNotNil(json);
}

- (void)testJSONFileViewControllerBlacklist {
    NSString *json = [self jsonToDictionaryCodeGeneratorWithFileName:@"sa_autotrack_viewcontroller_blacklist"];
    NSLog(@"Code Generator Result: %@", json);
    XCTAssertNotNil(json);
}

- (void)testJSONFileVisualizedPath {
    NSString *json = [self jsonToDictionaryCodeGeneratorWithFileName:@"sa_visualized_path"];
    NSLog(@"Code Generator Result: %@", json);
    XCTAssertNotNil(json);
}

- (void)testJSONFileMCC {
    NSString *json = [self jsonToDictionaryCodeGeneratorWithFileName:@"sa_mcc_mnc_mini"];
    NSLog(@"Code Generator Result: %@", json);
    XCTAssertNotNil(json);
}

- (void)testJSONFileAnalyticsFlows {
    NSString *json = [self jsonToDictionaryCodeGeneratorWithFileName:@"sensors_analytics_flow"];
    NSLog(@"Code Generator Result: %@", json);
    XCTAssertNotNil(json);
}

- (void)testJSONFileAnalyticsTasks {
    NSString *json = [self jsonToDictionaryCodeGeneratorWithFileName:@"sensors_analytics_task"];
    NSLog(@"Code Generator Result: %@", json);
    XCTAssertNotNil(json);
}

- (void)testJSONFileAnalyticsNodes {
    NSString *json = [self jsonToDictionaryCodeGeneratorWithFileName:@"sensors_analytics_node"];
    NSLog(@"Code Generator Result: %@", json);
    XCTAssertNotNil(json);
}

@end
