//
// SAPropertyValidatorTests.m
// SensorsAnalyticsTests
//
// Created by yuqiang on 2021/4/26.
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

@interface SATestValidator : NSObject<SAEventPropertyValidatorProtocol>

@end

@implementation SATestValidator

- (id)sensorsdata_validKey:(NSString *)key value:(id)value error:(NSError *__autoreleasing  _Nullable *)error {
    if ([key isEqualToString:@"sdk"]) {
        *error = SAPropertyError(30001, @"key is %@", @"sdk");
        return nil;
    }
    if ([value isEqualToString:@"sensors"]) {
        *error = SAPropertyError(30002, @"value is %@", @"sensors");
    }
    return [value uppercaseString];
}

@end

@interface SAPropertyValidatorTests : XCTestCase

@end

@implementation SAPropertyValidatorTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testValidProperties {
    NSDictionary *properties = @{};
    NSError *error = nil;
    [SAPropertyValidator validProperties:properties error:&error];
    XCTAssertNil(error);
}

- (void)testValidPropertiesWithNormalValueType {
    NSDictionary *properties = @{@"test_number": @(123),
                                 @"test_string": @"abc",
                                 @"test_date": NSDate.date,
                                 @"test_array": @[@"acb"]};
    NSError *error = nil;
    NSDictionary *result = [SAPropertyValidator validProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(result.allKeys.count > 0);
}

- (void)testValidPropertiesWithInvalidKey {
    NSDictionary *properties = @{@"999999": @(123)};
    NSError *error = nil;
    [SAPropertyValidator validProperties:properties error:&error];
    XCTAssertNotNil(error);
}

- (void)testValidPropertiesWithInvalidValue {
    NSDictionary *properties = @{@"abc": @[@(123)]};
    NSError *error = nil;
    [SAPropertyValidator validProperties:properties error:&error];
    XCTAssertNotNil(error);
}

- (void)testValidPropertiesWithCustomValidatorInvalidKey {
    SATestValidator *validator = [[SATestValidator alloc] init];
    NSDictionary *properties = @{@"sdk": @"test_sdk_key"};
    NSError *error = nil;
    [SAPropertyValidator validProperties:properties validator:validator error:&error];
    XCTAssertNotNil(error);
}

- (void)testValidPropertiesWithCustomValidatorInvalidValue {
    SATestValidator *validator = [[SATestValidator alloc] init];
    NSDictionary *properties = @{@"test_key": @"sensors"};
    NSError *error = nil;
    [SAPropertyValidator validProperties:properties validator:validator error:&error];
    XCTAssertNotNil(error);
}

- (void)testValidPropertiesWithCustomValidator {
    SATestValidator *validator = [[SATestValidator alloc] init];
    NSDictionary *properties = @{@"test_key": @"test_value"};
    NSError *error = nil;
    [SAPropertyValidator validProperties:properties validator:validator error:&error];
    XCTAssertNil(error);
}

@end
