//
// SAPropertyValidatorTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/25.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
