//
// SAUserDefaultsStorePluginTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2021/12/3.
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

#import <XCTest/XCTest.h>
#import "SAUserDefaultsStorePlugin.h"

static NSString * const kSAUserDefaultsStorePluginTestsKey = @"SAUserDefaultsStorePluginTests";

@interface SAUserDefaultsStorePluginTests : XCTestCase

@property (nonatomic, strong) SAUserDefaultsStorePlugin *plugin;

@end

@implementation SAUserDefaultsStorePluginTests

- (void)setUp {
    _plugin = [[SAUserDefaultsStorePlugin alloc] init];
}

- (void)tearDown {
    [_plugin removeObjectForKey:kSAUserDefaultsStorePluginTestsKey];
    _plugin = nil;
}

- (void)testStoreKey {
    NSArray *storeKeys = @[@"HasLaunchedOnce", @"HasTrackInstallation", @"HasTrackInstallationWithDisableCallback", @"com.sensorsdata.channeldebug.flag", @"SASDKConfig", @"SARequestRemoteConfigRandomTime"];
    for (NSString *key in storeKeys) {
        XCTAssert([self.plugin.storeKeys containsObject:key]);
    }
}

- (void)testType {
    XCTAssert([self.plugin.type isEqualToString:@"cn.sensorsdata.UserDefaults."]);
}

- (void)testSetStringObject {
    NSString *object = @"123";
    [self.plugin setObject:object forKey:kSAUserDefaultsStorePluginTestsKey];
    XCTAssertTrue([object isEqualToString:[self.plugin objectForKey:kSAUserDefaultsStorePluginTestsKey]]);
}

- (void)testSetArrayObject {
    NSArray *object = @[@"123"];
    [self.plugin setObject:object forKey:kSAUserDefaultsStorePluginTestsKey];
    XCTAssertTrue([object isEqualToArray:[self.plugin objectForKey:kSAUserDefaultsStorePluginTestsKey]]);
}

- (void)testSetDictionaryObject {
    NSDictionary *object = @{@"login_id": @"123"};
    [self.plugin setObject:object forKey:kSAUserDefaultsStorePluginTestsKey];
    XCTAssertTrue([object isEqualToDictionary:[self.plugin objectForKey:kSAUserDefaultsStorePluginTestsKey]]);
}

- (void)testSetDataObject {
    NSData *object = [self.plugin.type dataUsingEncoding:NSUTF8StringEncoding];
    [self.plugin setObject:object forKey:kSAUserDefaultsStorePluginTestsKey];
    XCTAssertTrue([object isEqualToData:[self.plugin objectForKey:kSAUserDefaultsStorePluginTestsKey]]);
}

- (void)testSetIntegerNumberObject {
    NSNumber *object = @(123);
    [self.plugin setObject:object forKey:kSAUserDefaultsStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAUserDefaultsStorePluginTestsKey]]);
}

- (void)testSetFloatNumberObject {
    NSNumber *object = @((float)1233.0);
    [self.plugin setObject:object forKey:kSAUserDefaultsStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAUserDefaultsStorePluginTestsKey]]);
}

- (void)testSetDoubleNumberObject {
    NSNumber *object = @(122223.00000);
    [self.plugin setObject:object forKey:kSAUserDefaultsStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAUserDefaultsStorePluginTestsKey]]);
}

- (void)testSetBoolObject {
    NSNumber *object = @(YES);
    [self.plugin setObject:object forKey:kSAUserDefaultsStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAUserDefaultsStorePluginTestsKey]]);
}

// Not Support
//- (void)testSetNullObject {
//   NSNull *object = [NSNull null];
//   [self.plugin setObject:object forKey:kSAUserDefaultsStorePluginTestsKey];
//   XCTAssertTrue([object isEqual:[self.plugin objectForKey:kSAUserDefaultsStorePluginTestsKey]]);
//}

- (void)testRemoveObjectForKey {
    NSString *object = @"123";
    [self.plugin setObject:object forKey:kSAUserDefaultsStorePluginTestsKey];
    [self.plugin removeObjectForKey:kSAUserDefaultsStorePluginTestsKey];
    XCTAssertNil([self.plugin objectForKey:kSAUserDefaultsStorePluginTestsKey]);
}

- (void)testPerformanceExample {
    [self measureBlock:^{
        NSString *object = @"123";
        [self.plugin setObject:object forKey:kSAUserDefaultsStorePluginTestsKey];
        [self.plugin objectForKey:kSAUserDefaultsStorePluginTestsKey];
        [self.plugin removeObjectForKey:kSAUserDefaultsStorePluginTestsKey];
    }];
}
@end
