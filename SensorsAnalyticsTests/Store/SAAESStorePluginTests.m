//
// SAAESStorePluginTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2021/12/2.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SAAESStorePlugin.h"

static NSString * const kSAAESStorePluginTestsKey = @"SAAESStorePluginTests";

@interface SAAESStorePluginTests : XCTestCase

@property (nonatomic, strong) SAAESStorePlugin *plugin;

@end

@implementation SAAESStorePluginTests

- (void)setUp {
    _plugin = [[SAAESStorePlugin alloc] init];
}

- (void)tearDown {
    [_plugin removeObjectForKey:kSAAESStorePluginTestsKey];
    _plugin = nil;
}

- (void)testType {
    XCTAssert([self.plugin.type isEqualToString:@"cn.sensorsdata.AES128."]);
}

- (void)testSetStringObject {
    NSString *object = @"123";
    [self.plugin setObject:object forKey:kSAAESStorePluginTestsKey];
    XCTAssertTrue([object isEqualToString:[self.plugin objectForKey:kSAAESStorePluginTestsKey]]);
}

- (void)testSetArrayObject {
    NSArray *object = @[@"123"];
    [self.plugin setObject:object forKey:kSAAESStorePluginTestsKey];
    XCTAssertTrue([object isEqualToArray:[self.plugin objectForKey:kSAAESStorePluginTestsKey]]);
}

- (void)testSetDictionaryObject {
    NSDictionary *object = @{@"login_id": @"123"};
    [self.plugin setObject:object forKey:kSAAESStorePluginTestsKey];
    XCTAssertTrue([object isEqualToDictionary:[self.plugin objectForKey:kSAAESStorePluginTestsKey]]);
}

- (void)testSetDataObject {
    NSData *object = [self.plugin.type dataUsingEncoding:NSUTF8StringEncoding];
    [self.plugin setObject:object forKey:kSAAESStorePluginTestsKey];
    XCTAssertTrue([object isEqualToData:[self.plugin objectForKey:kSAAESStorePluginTestsKey]]);
}

- (void)testSetIntegerNumberObject {
    NSNumber *object = @(123);
    [self.plugin setObject:object forKey:kSAAESStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAAESStorePluginTestsKey]]);
}

- (void)testSetFloatNumberObject {
    NSNumber *object = @((float)1233.0);
    [self.plugin setObject:object forKey:kSAAESStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAAESStorePluginTestsKey]]);
}

- (void)testSetDoubleNumberObject {
    NSNumber *object = @(122223.00000);
    [self.plugin setObject:object forKey:kSAAESStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAAESStorePluginTestsKey]]);
}

- (void)testSetBoolObject {
    NSNumber *object = @(YES);
    [self.plugin setObject:object forKey:kSAAESStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAAESStorePluginTestsKey]]);
}

- (void)testSetNullObject {
    NSNull *object = [NSNull null];
    [self.plugin setObject:object forKey:kSAAESStorePluginTestsKey];
    XCTAssertTrue([object isEqual:[self.plugin objectForKey:kSAAESStorePluginTestsKey]]);
}

- (void)testRemoveObjectForKey {
    NSString *object = @"123";
    [self.plugin setObject:object forKey:kSAAESStorePluginTestsKey];
    [self.plugin removeObjectForKey:kSAAESStorePluginTestsKey];
    XCTAssertNil([self.plugin objectForKey:kSAAESStorePluginTestsKey]);
}

- (void)testPerformanceExample {
    [self measureBlock:^{
        NSString *object = @"123";
        [self.plugin setObject:object forKey:kSAAESStorePluginTestsKey];
        [self.plugin objectForKey:kSAAESStorePluginTestsKey];
        [self.plugin removeObjectForKey:kSAAESStorePluginTestsKey];
    }];
}

@end
