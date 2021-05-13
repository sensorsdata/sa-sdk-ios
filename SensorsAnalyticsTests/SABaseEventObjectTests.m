//
// SABaseEventObjectTests.m
// SensorsAnalyticsTests
//
// Created by yuqiang on 2021/4/23.
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
#import "SABaseEventObject.h"
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"

@interface SABaseEventObjectTests : XCTestCase

@end

@implementation SABaseEventObjectTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:nil];
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testEvent {
    // eventId 结构为 {eventName}_D3AC265B_3CC2_4C45_B8F0_3E05A83A9DAE_SATimer，新增后缀长度为 44
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSString *eventName = @"testEventName";
    NSString *uuidString = [NSUUID.UUID.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    object.eventId = [NSString stringWithFormat:@"%@_%@%@", eventName, uuidString, kSAEventIdSuffix];
    XCTAssertTrue([eventName isEqualToString:object.event]);
}

- (void)testEventId {
    // eventId 结构为 {eventName}_D3AC265B_3CC2_4C45_B8F0_3E05A83A9DAE_SATimer，新增后缀长度为 44
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSString *eventName = @"";
    NSString *uuidString = [NSUUID.UUID.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    object.eventId = [NSString stringWithFormat:@"%@_%@%@", eventName, uuidString, kSAEventIdSuffix];
    XCTAssertTrue([eventName isEqualToString:object.event]);
}

- (void)testEventNil {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    XCTAssertNil(object.event);
}

- (void)testEventEmpty {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    object.eventId = @"";
    XCTAssertTrue([@"" isEqualToString:object.event]);
}

- (void)testIsSignUp {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    XCTAssertFalse(object.isSignUp);
}

- (void)testValidateEventWithError {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testJSONObject {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSMutableDictionary *jsonObject = [object jsonObject];
    XCTAssertTrue(jsonObject.count > 0);
}

- (void)testJSONObjectWithLib {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSMutableDictionary *jsonObject = [object jsonObject];
    NSDictionary *lib = jsonObject[kSAEventLib];
    XCTAssertTrue(lib.count > 0);
}

- (void)testAddEventPropertiesWithEmpty {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    [object addEventProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddEventProperties {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    [object addEventProperties:properties];
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddChannelPropertiesWithEmpty {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    [object addChannelProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddChannelProperties {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    [object addChannelProperties:properties];
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddModulePropertiesWithEmpty {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    [object addModuleProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddModuleProperties {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    [object addModuleProperties:properties];
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddSuperPropertiesWithEmpty {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    [object addSuperProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddSuperProperties {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    [object addSuperProperties:properties];
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddCustomPropertiesWithEmpty {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
}

- (void)testAddCustomProperties {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([properties isEqualToDictionary:object.properties]);
}

- (void)testAddCustomPropertiesWithNumberKey {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"123abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNotNil(error);
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddCustomPropertiesWithIdKey {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"id": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNotNil(error);
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddCustomPropertiesWithTimeKey {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"time": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNotNil(error);
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddCustomPropertiesWithProject {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"$project": @"projectName"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddCustomPropertiesWithToken {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"$token": @"token value"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddCustomPropertiesTime1 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"$time": NSDate.date};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddCustomPropertiesWithInvalidTime {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(kSAEventCommonOptionalPropertyTimeInt - 2000) / 1000];
    NSDictionary *properties = @{@"$time": date};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(object.properties.count == 0);
    XCTAssertTrue(![date isEqualToDate:[NSDate dateWithTimeIntervalSince1970:(object.timeStamp / 1000)]]);
}

- (void)testAddCustomPropertiesWithValidTime {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(kSAEventCommonOptionalPropertyTimeInt + 2000) / 1000];
    NSDictionary *properties = @{@"$time": date};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(object.properties.count == 0);
    XCTAssertTrue([date isEqualToDate:[NSDate dateWithTimeIntervalSince1970:(object.timeStamp / 1000)]]);
}

- (void)testAddCustomPropertiesWithNumberTimeValue {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"$time": @(11111111)};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddCustomPropertiesDeviceId {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"$device_id": @"deviceId"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddReferrerTitleWithEmpty {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    [object addReferrerTitleProperty:@""];
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddReferrerTitle {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    [object addReferrerTitleProperty:@"testTitle"];
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddDurationPropertyWithNil {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSNumber *number = nil;
    [object addDurationProperty:number];
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddDurationProperty {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    [object addDurationProperty:@(23)];
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testSensorsdata_validKeyWithNumberKey {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSError *error = nil;
    [object sensorsdata_validKey:@(123) value:@"abc" error:&error];
    XCTAssertNotNil(error);
}

- (void)testSensorsdata_validKeyWithDigitalKey {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSError *error = nil;
    [object sensorsdata_validKey:@"123" value:@"abc" error:&error];
    XCTAssertNotNil(error);
}

- (void)testSensorsdata_validKeyWithStringKey {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSError *error = nil;
    [object sensorsdata_validKey:@"abc" value:NSDate.date error:&error];
    XCTAssertNil(error);
}

- (void)testSensorsdata_validKeyWithArrayStringValue {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSError *error = nil;
    [object sensorsdata_validKey:@"abc" value:@[@"123"] error:&error];
    XCTAssertNil(error);
}

- (void)testSensorsdata_validKeyWithArrayNumberValue {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSError *error = nil;
    [object sensorsdata_validKey:@"abc" value:@[@(123)] error:&error];
    XCTAssertNotNil(error);
}

@end
