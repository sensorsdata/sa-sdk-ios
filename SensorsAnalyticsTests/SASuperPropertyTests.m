//
// SASuperPropertyTests.m
// SensorsAnalyticsTests
//
// Created by yuqiang on 2021/4/19.
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
#import "SASuperProperty.h"

@interface SASuperPropertyTests : XCTestCase

@property (nonatomic, strong) SASuperProperty *superPorperty;

@end

@implementation SASuperPropertyTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _superPorperty = [[SASuperProperty alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _superPorperty = nil;
}

- (void)testRegisterSuperProperties {
    [self.superPorperty registerSuperProperties:@{@"testRegister": @"testRegisterValue"}];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count > 0);
}

- (void)testClearSuperProperties {
    [self.superPorperty registerSuperProperties:@{@"testRegister": @"testRegisterValue"}];
    [self.superPorperty clearSuperProperties];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);
}

- (void)testCurrentSuperProperties {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"abc123": @"abc123_value"}];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 1);
}


- (void)testRegisterSuperPropertiesForInvalid {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"123abc": @"123abcValue"}];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);
}

- (void)testRepeatRegisterSuperProperties {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"abc": @"abcValue"}];
    [self.superPorperty registerSuperProperties:@{@"ABC": @"ABCValue"}];
    NSDictionary *result = [self.superPorperty currentSuperProperties];
    XCTAssertTrue([@{@"ABC": @"ABCValue"} isEqualToDictionary:result]);
}

- (void)testRepeatRegisterSuperPropertiesWithSameKey {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"abc": @"abcValue", @"ABC": @"ABCValue"}];
    NSDictionary *result = [self.superPorperty currentSuperProperties];
    XCTAssertTrue([(@{@"abc":@"abcValue", @"ABC": @"ABCValue"}) isEqualToDictionary:result]);
}

- (void)testUnregisterSuperProperty {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"abc": @"abcValue", @"ABC": @"ABCValue"}];
    [self.superPorperty unregisterSuperProperty:@"ABC"];
    NSDictionary *result = [self.superPorperty currentSuperProperties];
    XCTAssertTrue([(@{@"abc": @"abcValue"}) isEqualToDictionary:result]);

    [self.superPorperty unregisterSuperProperty:@"abc"];
    NSDictionary *result2 = [self.superPorperty currentSuperProperties];
    XCTAssertTrue([(@{}) isEqualToDictionary:result2]);
}

- (void)testUnregisterSuperPropertyWithNilKey {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"abc": @"abcValue", @"ABC": @"ABCValue"}];
    NSString *unregisterKey = nil;
    [self.superPorperty unregisterSuperProperty:unregisterKey];
    NSDictionary *result = [self.superPorperty currentSuperProperties];
    XCTAssertTrue([(@{@"abc": @"abcValue", @"ABC": @"ABCValue"}) isEqualToDictionary:result]);

    [self.superPorperty unregisterSuperProperty:@"abc"];
    NSDictionary *result2 = [self.superPorperty currentSuperProperties];
    XCTAssertTrue([(@{@"ABC": @"ABCValue"}) isEqualToDictionary:result2]);
}

- (void)testRegisterSuperPropertyForInvalidKey {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"123abc": @"123abcValue"}];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);
}

- (void)testRegisterSuperPropertyForNumberKey {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@(123): @"123"}];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);
}

- (void)testRegisterSuperPropertyForReserveKey {
    [self.superPorperty clearSuperProperties];

    [self.superPorperty registerSuperProperties:@{@"date": @"date_value",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"datetime": @"datetimeValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"distinct_id": @"distinct_idValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"event": @"eventValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"events": @"eventsValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"first_id": @"first_idValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"id": @"idValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"original_id": @"original_idValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"properties": @"propertiesValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"second_id": @"second_idValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"time": @"timeValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"user_id": @"user_idValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

    [self.superPorperty registerSuperProperties:@{@"users": @"usersValue",
                                                  @"normalKey": @"normalValue",
                                                }];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);

}

- (void)testRegisterSuperPropertyForLongLengthKey {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"_aaaaaaaaaa_aaaaaaaaaa_aaaaaaaaaa_aaaaaaaaaa_aaaaaaaaaa_aaaaaaaaaa_aaaaaaaaaa_aaaaaaaaaa_aaaaaaaaaa_a": @"测试 key 长度"}];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);
}

- (void)testUnregisterSameLetterSuperPropertiesForPart {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"abc": @"abcValue",
                                                  @"BCD": @"BCDValue",
                                                  @"eFg": @"eFgValue",}];
    [self.superPorperty unregisterSameLetterSuperProperties:@{@"ABC": @"ABCValue",
                                                              @"EfG": @"EfGValue"}];
    XCTAssertTrue([(@{@"BCD": @"BCDValue"}) isEqualToDictionary:self.superPorperty.currentSuperProperties]);
}

- (void)testUnregisterSameLetterSuperPropertiesForAll {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"BCD": @"BCDValue"}];
    [self.superPorperty unregisterSameLetterSuperProperties:@{@"bcd": @"bcdValue"}];
    XCTAssertTrue([(@{}) isEqualToDictionary:self.superPorperty.currentSuperProperties]);
}

- (void)testUnregisterDifferentLetterSuperProperties {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"BCD": @"BCDValue"}];
    [self.superPorperty unregisterSameLetterSuperProperties:@{@"abcd": @"bcdValue"}];
    XCTAssertTrue([(@{@"BCD": @"BCDValue"}) isEqualToDictionary:self.superPorperty.currentSuperProperties]);
}

- (void)testRegisterDynamicSuperProperties {
    [self.superPorperty registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
        return @{@"hhh": @(123),
                 @"jjj": @[@"j", @"jj", @"jjj"]};
    }];
    NSDictionary *reuslt = [self.superPorperty acquireDynamicSuperProperties];
    XCTAssertTrue([(@{@"hhh": @(123),@"jjj": @[@"j", @"jj", @"jjj"]}) isEqualToDictionary:reuslt]);
}

- (void)testAcquireDynamicSuperProperties {
    [self.superPorperty registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
        return @{@"aaa": @"aaaValue"};
    }];
    NSDictionary *reuslt = [self.superPorperty acquireDynamicSuperProperties];
    XCTAssertTrue([(@{@"aaa": @"aaaValue"}) isEqualToDictionary:reuslt]);
}

- (void)testAcquireDynamicSuperPropertiesWithNil {
    NSDictionary<NSString *, id> *(^block)(void) = nil;
    [self.superPorperty registerDynamicSuperProperties:block];
    XCTAssertNil([self.superPorperty acquireDynamicSuperProperties]);
}

- (void)testRegisterDynamicSuperPropertiesWithNumberKey {
    [self.superPorperty registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
        return @{@"hhh": @(123),
                 @"123jjj": @[@"j", @"jj", @"jjj"]};
    }];
    XCTAssertNil([self.superPorperty acquireDynamicSuperProperties]);
}

- (void)testRegisterHybrid {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"fff": @(456)}];
    [self.superPorperty registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
        return @{@"hhh": @(123),
                 @"jjj": @[@"j", @"jj", @"jjj"]};
    }];
    NSDictionary *reuslt = [self.superPorperty acquireDynamicSuperProperties];
    XCTAssertTrue([(@{@"fff": @(456)}) isEqualToDictionary:self.superPorperty.currentSuperProperties]);
    XCTAssertTrue([(@{@"hhh": @(123),@"jjj": @[@"j", @"jj", @"jjj"]}) isEqualToDictionary:reuslt]);
}

- (void)testRegisterHybridWithSameKey {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"hhh": @(456)}];
    [self.superPorperty registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
        return @{@"hhh": @(123),
                 @"jjj": @[@"j", @"jj", @"jjj"]};
    }];
    NSDictionary *reuslt = [self.superPorperty acquireDynamicSuperProperties];
    XCTAssertTrue([(@{}) isEqualToDictionary:self.superPorperty.currentSuperProperties]);
    XCTAssertTrue([(@{@"hhh": @(123),@"jjj": @[@"j", @"jj", @"jjj"]}) isEqualToDictionary:reuslt]);
}

- (void)testRegisterHybridSomeKeyIgnoreCase {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"HhH": @(456)}];
    [self.superPorperty registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
        return @{@"hhh": @(123),
                 @"jjj": @[@"j", @"jj", @"jjj"]};
    }];
    NSDictionary *reuslt = [self.superPorperty acquireDynamicSuperProperties];
    XCTAssertTrue([(@{}) isEqualToDictionary:self.superPorperty.currentSuperProperties]);
    XCTAssertTrue([(@{@"hhh": @(123),@"jjj": @[@"j", @"jj", @"jjj"]}) isEqualToDictionary:reuslt]);
}


@end
