//
// SASuperPropertyTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/22.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

@interface SASuperPropertyTest : XCTestCase

@property (nonatomic, strong) SASuperProperty *superProperty;

@end

@implementation SASuperPropertyTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.superProperty = [[SASuperProperty alloc] init];
    [self.superProperty clearSuperProperties];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testRegisterSuperPropertiesWithEmptyDictionary {
    [self.superProperty registerSuperProperties:@{}];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 0);
}

- (void)testRegisterSuperPropertiesWithNilDictionary {
    NSDictionary *dic = nil;
    [self.superProperty registerSuperProperties:dic];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 0);
}

- (void)testRegisterSuperPropertiesWithNotDictionary {
    NSDictionary *dic = (NSDictionary *)@"ABC";
    [self.superProperty registerSuperProperties:dic];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 0);
}

- (void)testRegisterSuperPropertiesWithDictionary {
    [self.superProperty registerSuperProperties:@{@"ABC" : @"abc"}];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 1);
    XCTAssertTrue([superProperties[@"ABC"] isEqualToString:@"abc"]);
}

- (void)testUnregisterSuperPropertyWithEmptyString {
    [self.superProperty registerSuperProperties:@{@"ABC" : @"abc"}];
    [self.superProperty unregisterSuperProperty:@""];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 1);
    XCTAssertTrue([superProperties[@"ABC"] isEqualToString:@"abc"]);
}

- (void)testUnregisterSuperPropertyWithNilString {
    [self.superProperty registerSuperProperties:@{@"ABC" : @"abc"}];
    NSString *superProperty = nil;
    [self.superProperty unregisterSuperProperty:superProperty];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 1);
    XCTAssertTrue([superProperties[@"ABC"] isEqualToString:@"abc"]);
}

- (void)testUnregisterSuperPropertyWithNotKeyString {
    [self.superProperty registerSuperProperties:@{@"ABC" : @"abc"}];
    [self.superProperty unregisterSuperProperty:@"A"];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 1);
    XCTAssertTrue([superProperties[@"ABC"] isEqualToString:@"abc"]);
}

- (void)testUnregisterSuperPropertyWithKeyString {
    [self.superProperty registerSuperProperties:@{@"ABC" : @"abc"}];
    [self.superProperty unregisterSuperProperty:@"ABC"];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 0);
}

- (void)testClearSuperProperties {
    [self.superProperty registerSuperProperties:@{@"ABC" : @"abc"}];
    [self.superProperty clearSuperProperties];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 0);
}

- (void)testUnregisterSameLetterSuperPropertiesWithEmptyDictionary {
    [self.superProperty registerSuperProperties:@{@"ABC" : @"abc"}];
    [self.superProperty unregisterSameLetterSuperProperties:@{}];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 1);
    XCTAssertTrue([superProperties[@"ABC"] isEqualToString:@"abc"]);
}

- (void)testUnregisterSameLetterSuperPropertiesWithNilDictionary {
    [self.superProperty registerSuperProperties:@{@"ABC" : @"abc"}];
    NSDictionary *property = nil;
    [self.superProperty unregisterSameLetterSuperProperties:property];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 1);
    XCTAssertTrue([superProperties[@"ABC"] isEqualToString:@"abc"]);
}

- (void)testUnregisterSameLetterSuperPropertiesWithNotDictionary {
//   [self.superProperty registerSuperProperties:@{@"ABC" : @"abc"}];
//   NSDictionary *property = (NSDictionary *)@"ABC";
//   [self.superProperty unregisterSameLetterSuperProperties:property];
//   NSDictionary *superProperties = [self.superProperty currentSuperProperties];
//   XCTAssertTrue([superProperties isKindOfClass:[NSDictionary class]]);
//   XCTAssertTrue(superProperties.count == 1);
//   XCTAssertTrue([superProperties[@"ABC"] isEqualToString:@"abc"]);
}

- (void)testUnregisterSameLetterSuperPropertiesWithDictionary {
    [self.superProperty registerSuperProperties:@{@"ABC" : @"abc", @"DEF" : @"def"}];
    [self.superProperty unregisterSameLetterSuperProperties:@{@"ABC" : @"a", @"deF" : @"d"}];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertTrue(superProperties.count == 0);
}

- (void)testRegisterSameLetterSuperProperties {
    [self.superProperty registerSuperProperties:@{@"ABC" : @"A1"}];
    [self.superProperty registerSuperProperties:@{@"abc" : @"a1"}];
    NSDictionary *superProperties = [self.superProperty currentSuperProperties];
    XCTAssertNil(superProperties[@"ABC"]);
    XCTAssertTrue([superProperties[@"abc"] isEqualToString:@"a1"]);
}

- (void)testRegisterDynamicSuperPropertiesWithEmptyDictionary {
    [self.superProperty registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
        return @{};
    }];
    NSDictionary *dynamicSuperProperties = [self.superProperty acquireDynamicSuperProperties];
    XCTAssertTrue(dynamicSuperProperties.count == 0);
}

- (void)testRegisterDynamicSuperPropertiesWithNilDictionary {
    [self.superProperty registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
        return nil;
    }];
    NSDictionary *dynamicSuperProperties = [self.superProperty acquireDynamicSuperProperties];
    XCTAssertNil(dynamicSuperProperties);
}

- (void)testRegisterDynamicSuperPropertiesWithNotDictionary {
    [self.superProperty registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
        NSDictionary *dic = (NSDictionary *)@"ABC";
        return dic;
    }];
    NSDictionary *dynamicSuperProperties = [self.superProperty acquireDynamicSuperProperties];
    XCTAssertNil(dynamicSuperProperties);
}

- (void)testRegisterDynamicSuperPropertiesWithDictionary {
    [self.superProperty registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
        return @{@"ABC" : @"abc"};
    }];
    NSDictionary *dynamicSuperProperties = [self.superProperty acquireDynamicSuperProperties];
    XCTAssertTrue(dynamicSuperProperties.count == 1);
    XCTAssertTrue([dynamicSuperProperties[@"ABC"] isEqualToString:@"abc"]);
}

- (void)testRegisterSameLetterDynamicSuperProperties {
    [self.superProperty registerSuperProperties:@{@"ABC" : @"A1"}];
    [self.superProperty registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
        return @{@"abc" : @"a1"};
    }];
    
    NSDictionary *superPropertiesBeforeDynamic = [self.superProperty currentSuperProperties];
    NSDictionary *dynamicSuperProperties = [self.superProperty acquireDynamicSuperProperties];
    NSDictionary *superPropertiesAfterDynamic = [self.superProperty currentSuperProperties];
    
    XCTAssertTrue([superPropertiesBeforeDynamic[@"ABC"] isEqualToString:@"A1"]);
    XCTAssertTrue([dynamicSuperProperties[@"abc"] isEqualToString:@"a1"]);
    XCTAssertTrue(superPropertiesAfterDynamic.count == 0);
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
