//
// SATrackEventObjectTests.m
// SensorsAnalyticsTests
//
// Created by yuqiang on 2021/4/25.
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
#import "SATrackEventObject.h"
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"
#import "SAPresetProperty.h"

@interface SATrackEventObjectTests : XCTestCase

@end

@implementation SATrackEventObjectTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:nil];
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testEventId {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@"eventId"];
    XCTAssertTrue([@"eventId" isEqualToString:object.event]);
}

- (void)testValidateEventWithString {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@"eventId"];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testValidateEventWithNumber {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@(123)];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNotNil(error);
}

- (void)testValidateEventWithEmpty {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNotNil(error);
}

- (void)testValidateEventWithNil {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:nil];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNotNil(error);
}

- (void)testValidateEventWithDigital {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@"123abc"];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNotNil(error);
}

- (void)testAddEventPropertiesWithEmpty {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    [object addEventProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddEventProperties {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ccc": @[@"123"]};
    [object addEventProperties:properties];
    XCTAssertTrue([properties isEqualToDictionary:object.properties]);
}

- (void)testAddModulePropertiesWithEmpty {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    [object addModuleProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddModuleProperties {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ccc": @[@"123"]};
    [object addModuleProperties:properties];
    XCTAssertTrue([properties isEqualToDictionary:object.properties]);
}

- (void)testAddSuperProperties {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ccc": @[@"123"]};
    [object addSuperProperties:properties];
    XCTAssertTrue([properties isEqualToDictionary:object.properties]);
}

- (void)testAddSuperPropertiesWithLibAppVersion {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSDictionary *properties = @{@"abc": @"abcValue", kSAEventPresetPropertyAppVersion: @"v2.3.0"};
    [object addSuperProperties:properties];
    XCTAssertTrue([properties isEqualToDictionary:object.properties]);
    XCTAssertTrue([@"v2.3.0" isEqualToString:object.lib.appVersion]);
}

- (void)testAddCustomPropertiesWithLibMethodCode {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSDictionary *properties = @{@"abc": @"abcValue"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.lib.method]);
}

- (void)testAddCustomPropertiesWithNumberLibMethod {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSDictionary *properties = @{@"abc": @"abcValue", kSAEventPresetPropertyLibMethod: @(123)};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([@(123) isEqualToNumber:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.lib.method]);
}

- (void)testAddCustomPropertiesWithStringLibMethod {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSDictionary *properties = @{@"abc": @"abcValue", kSAEventPresetPropertyLibMethod: @"test_lib"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.lib.method]);
}

- (void)testAddCustomPropertiesWithAutoLibMethod {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSDictionary *properties = @{@"abc": @"abcValue", kSAEventPresetPropertyLibMethod: kSALibMethodAuto};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.lib.method]);
}

- (void)testAddCustomPropertiesWithCodeLibMethod {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSDictionary *properties = @{@"abc": @"abcValue", kSAEventPresetPropertyLibMethod: kSALibMethodCode};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.lib.method]);
}

- (void)testAddCustomPropertiesWithTime {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSDictionary *properties = @{@"time": @"abcValue"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNotNil(error);
}

- (void)testAddReferrerTitleProperty {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    [object addReferrerTitleProperty:@"test_referrer_title"];
    XCTAssertTrue([@"test_referrer_title" isEqualToString:object.properties[kSAEeventPropertyReferrerTitle]]);
}

- (void)testAddDurationProperty {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    [object addDurationProperty:@(123)];
    XCTAssertTrue([@(123) isEqualToNumber:object.properties[@"event_duration"]]);
}

- (void)testAddDurationPropertyWithNil {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    [object addDurationProperty:nil];
    XCTAssertNil(object.properties[@"event_duration"]);
}

- (void)testCustomEventObject {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:@"event"];
    XCTAssertTrue([object.type isEqualToString:kSAEventTypeTrack]);
}

- (void)testCustomEventObjectAddChannelPropertiesWithEmpty {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:@"event"];
    [object addChannelProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testCustomEventObjectAddChannelProperties {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:@"event"];
    [object addChannelProperties:@{@"jjj": @[@"123"]}];
    XCTAssertTrue([@{@"jjj": @[@"123"]} isEqualToDictionary:object.properties]);
}

- (void)testCustomEventObjectValidateEventWithErrorForReserveEvent {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:@"event"];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNotNil(error);
}

- (void)testCustomEventObjectValidateEventWithError {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:@"eventName"];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testCustomEventObjectValidateEventWithErrorForAppStart {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:kSAEventNameAppStart];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testCustomEventObjectValidateEventWithErrorForAppStartPassively {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:kSAEventNameAppStartPassively];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testCustomEventObjectValidateEventWithErrorForAppEnd {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:kSAEventNameAppEnd];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testCustomEventObjectValidateEventWithErrorForAppViewScreen {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:kSAEventNameAppViewScreen];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testCustomEventObjectValidateEventWithErrorForAppClick {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:kSAEventNameAppClick];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testCustomEventObjectValidateEventWithErrorForSignUp {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:kSAEventNameSignUp];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testCustomEventObjectValidateEventWithErrorForAppCrashed {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:kSAEventNameAppCrashed];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testSignUpEventObjectForIsSignUp {
    SASignUpEventObject *object = [[SASignUpEventObject alloc] initWithEventId:kSAEventNameSignUp];
    XCTAssertTrue(object.isSignUp);
}

- (void)testSignUpEventObjectForEventType {
    SASignUpEventObject *object = [[SASignUpEventObject alloc] initWithEventId:kSAEventNameSignUp];
    XCTAssertTrue([kSAEventTypeSignup isEqualToString:object.type]);
}

- (void)testSignUpEventObjectAddModulePropertiesWithEmpty {
    SASignUpEventObject *object = [[SASignUpEventObject alloc] initWithEventId:kSAEventNameSignUp];
    [object addModuleProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testSignUpEventObjectAddModuleProperties {
    SASignUpEventObject *object = [[SASignUpEventObject alloc] initWithEventId:kSAEventNameSignUp];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ccc": @[@"123"]};
    [object addModuleProperties:properties];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testSignUpEventObjectJsonObjectWithOriginalId {
    SASignUpEventObject *object = [[SASignUpEventObject alloc] initWithEventId:kSAEventNameSignUp];
    object.originalId = @"test_signup_originalId";
    NSDictionary *properties = [object jsonObject];
    XCTAssertTrue([properties[@"original_id"] isEqualToString:@"test_signup_originalId"]);
}

- (void)testAutoTrackEventObject {
    SAAutoTrackEventObject *object = [[SAAutoTrackEventObject alloc] initWithEventId:kSAEventNameAppStart];
    XCTAssertTrue([kSAEventTypeTrack isEqualToString:object.type]);
}

- (void)testAutoTrackEventObjectAddCustomPropertiesWithNil {
    SAAutoTrackEventObject *object = [[SAAutoTrackEventObject alloc] initWithEventId:kSAEventNameAppStart];
    NSDictionary *properties = nil;
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.lib.method]);
}

- (void)testAutoTrackEventObjectAddCustomProperties {
    SAAutoTrackEventObject *object = [[SAAutoTrackEventObject alloc] initWithEventId:kSAEventNameAppStart];
    NSDictionary *properties = @{@"abc": @"abcValue"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.lib.method]);
}

- (void)testAutoTrackEventObjectAddCustomPropertiesWithAppStartLibDetail {
    SAAutoTrackEventObject *object = [[SAAutoTrackEventObject alloc] initWithEventId:kSAEventNameAppStart];
    NSDictionary *properties = @{@"abc": @"abcValue", @"$screen_name": @"HomePageViewController"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.lib.method]);
    XCTAssertNil(object.lib.detail);
}

- (void)testAutoTrackEventObjectAddCustomPropertiesWithAppEndLibDetail {
    SAAutoTrackEventObject *object = [[SAAutoTrackEventObject alloc] initWithEventId:kSAEventNameAppEnd];
    NSDictionary *properties = @{@"abc": @"abcValue", @"$screen_name": @"HomePageViewController"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.lib.method]);
    XCTAssertNil(object.lib.detail);
}

- (void)testAutoTrackEventObjectAddCustomPropertiesWithAppViewScreenLibDetail {
    SAAutoTrackEventObject *object = [[SAAutoTrackEventObject alloc] initWithEventId:kSAEventNameAppViewScreen];
    NSDictionary *properties = @{@"abc": @"abcValue", @"$screen_name": @"HomePageViewController"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.lib.method]);
    XCTAssertNotNil(object.lib.detail);
}

- (void)testAutoTrackEventObjectAddCustomPropertiesWithAppClickLibDetail {
    SAAutoTrackEventObject *object = [[SAAutoTrackEventObject alloc] initWithEventId:kSAEventNameAppClick];
    NSDictionary *properties = @{@"abc": @"abcValue", @"$screen_name": @"HomePageViewController"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.lib.method]);
    XCTAssertNotNil(object.lib.detail);
}

- (void)testPresetEventObject {
    SAPresetEventObject *object = [[SAPresetEventObject alloc] initWithEventId:@"eventName"];
    XCTAssertTrue([kSAEventTypeTrack isEqualToString:object.type]);
}

@end
