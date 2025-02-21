//
// SAFileStorePluginTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2021/12/3.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SAFileStorePlugin.h"

static NSString * const kSAFileStorePluginTestsKey = @"SAFileStorePluginTests";

@interface SAFileStorePluginTests : XCTestCase

@property (nonatomic, strong) SAFileStorePlugin *plugin;

@end

@implementation SAFileStorePluginTests

- (void)setUp {
    _plugin = [[SAFileStorePlugin alloc] init];
}

- (void)tearDown {
    [_plugin removeObjectForKey:kSAFileStorePluginTestsKey];
    _plugin = nil;
}

- (void)testStoreKey {
    NSArray *storeKeys = @[@"$channel_device_info", @"latest_utms", @"SAEncryptSecretKey", @"distinct_id", @"com.sensorsdata.identities", @"login_id", @"com.sensorsdata.loginidkey", @"first_day", @"super_properties", @"SAVisualPropertiesConfig"];
    for (NSString *key in storeKeys) {
        XCTAssert([self.plugin.storeKeys containsObject:key]);
    }
}

- (void)testType {
    XCTAssert([self.plugin.type isEqualToString:@"cn.sensorsdata.File."]);
}

- (void)testSetStringObject {
    NSString *object = @"123";
    [self.plugin setObject:object forKey:kSAFileStorePluginTestsKey];
    XCTAssertTrue([object isEqualToString:[self.plugin objectForKey:kSAFileStorePluginTestsKey]]);
}

- (void)testSetArrayObject {
    NSArray *object = @[@"123"];
    [self.plugin setObject:object forKey:kSAFileStorePluginTestsKey];
    XCTAssertTrue([object isEqualToArray:[self.plugin objectForKey:kSAFileStorePluginTestsKey]]);
}

- (void)testSetNSSetObject {
    NSSet *set = [[NSSet alloc] initWithArray:@[@"哈哈12casdz", @(123)]];
    [self.plugin setObject:set forKey:kSAFileStorePluginTestsKey];
    XCTAssertTrue([set isEqualToSet: [self.plugin objectForKey:kSAFileStorePluginTestsKey]]);
}

- (void)testSetDictionaryObject {
    NSDictionary *object = @{@"login_id": @"123"};
    [self.plugin setObject:object forKey:kSAFileStorePluginTestsKey];
    XCTAssertTrue([object isEqualToDictionary:[self.plugin objectForKey:kSAFileStorePluginTestsKey]]);
}

- (void)testSetDataObject {
    NSData *object = [self.plugin.type dataUsingEncoding:NSUTF8StringEncoding];
    [self.plugin setObject:object forKey:kSAFileStorePluginTestsKey];
    XCTAssertTrue([object isEqualToData:[self.plugin objectForKey:kSAFileStorePluginTestsKey]]);
}

- (void)testSetIntegerNumberObject {
    NSNumber *object = @(123);
    [self.plugin setObject:object forKey:kSAFileStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAFileStorePluginTestsKey]]);
}

- (void)testSetFloatNumberObject {
    NSNumber *object = @((float)1233.0);
    [self.plugin setObject:object forKey:kSAFileStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAFileStorePluginTestsKey]]);
}

- (void)testSetDoubleNumberObject {
    NSNumber *object = @(122223.00000);
    [self.plugin setObject:object forKey:kSAFileStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAFileStorePluginTestsKey]]);
}

- (void)testSetBoolObject {
    NSNumber *object = @(YES);
    [self.plugin setObject:object forKey:kSAFileStorePluginTestsKey];
    XCTAssertTrue([object isEqualToNumber:[self.plugin objectForKey:kSAFileStorePluginTestsKey]]);
}

- (void)testSetNullObject {
    NSNull *object = [NSNull null];
    [self.plugin setObject:object forKey:kSAFileStorePluginTestsKey];
    XCTAssertTrue([object isEqual:[self.plugin objectForKey:kSAFileStorePluginTestsKey]]);
}

- (void)testRemoveObjectForKey {
    NSString *object = @"123";
    [self.plugin setObject:object forKey:kSAFileStorePluginTestsKey];
    [self.plugin removeObjectForKey:kSAFileStorePluginTestsKey];
    XCTAssertNil([self.plugin objectForKey:kSAFileStorePluginTestsKey]);
}

- (void)testPerformanceExample {
    [self measureBlock:^{
        NSString *object = @"123";
        [self.plugin setObject:object forKey:kSAFileStorePluginTestsKey];
        [self.plugin objectForKey:kSAFileStorePluginTestsKey];
        [self.plugin removeObjectForKey:kSAFileStorePluginTestsKey];
    }];
}

@end
