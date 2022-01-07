//
// SAPropertyValidatorTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/25.
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
#import "SAPropertyValidator.h"

@interface SAPropertyValidatorTest : XCTestCase <SAEventPropertyValidatorProtocol>

@end

@implementation SAPropertyValidatorTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPropertyValidatorWithEmptyDictionary {
    NSMutableDictionary *result = [SAPropertyValidator validProperties:@{} validator:self];
    XCTAssertEqual(result.count, 0);
}

- (void)testPropertyValidatorWithNilDictionary {
    NSDictionary *properties = nil;
    NSMutableDictionary *result = [SAPropertyValidator validProperties:properties validator:self];
    XCTAssertNil(result);
}

- (void)testPropertyValidatorWithNotDictionaryType {
    NSDictionary *properties = (NSDictionary *)@"ABC";
    NSMutableDictionary *result = [SAPropertyValidator validProperties:properties validator:self];
    XCTAssertNil(result);
}

- (void)testPropertyValidatorWithValidatorDictionaryType {
    NSDictionary *properties = @{@"ABC" : @"abc"};
    NSMutableDictionary *result = [SAPropertyValidator validProperties:properties validator:self];
    XCTAssertTrue([result[@"ABC"] isEqualToString:@"abc"]);
}

- (void)testPropertyValidatorWithNotValidatorDictionaryType {
    NSDictionary *properties = @{@"ABC" : @{@"M" : @"m"}};
    NSMutableDictionary *result = [SAPropertyValidator validProperties:properties validator:self];
    XCTAssertEqual(result.count, 0);
}

- (id)sensorsdata_validKey:(NSString *)key value:(id)value error:(NSError *__autoreleasing  _Nullable *)error {
    if (![key conformsToProtocol:@protocol(SAPropertyKeyProtocol)]) {
        *error = SAPropertyError(10004, @"Property Key should by %@", [key class]);
        return nil;
    }

    // key 校验
    [(id <SAPropertyKeyProtocol>)key sensorsdata_isValidPropertyKeyWithError:error];
    if (*error) {
        return nil;
    }

    if (![value conformsToProtocol:@protocol(SAPropertyValueProtocol)]) {
        *error = SAPropertyError(10005, @"%@ property values must be NSString, NSNumber, NSSet, NSArray or NSDate. got: %@ %@", self, [value class], value);
        return nil;
    }

    // value 转换
    return [(id <SAPropertyValueProtocol>)value sensorsdata_propertyValueWithKey:key error:error];
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
