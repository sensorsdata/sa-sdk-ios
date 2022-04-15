//
// SAIdentifierTest.m
// SensorsAnalyticsTests
//
// Created by 彭远洋 on 2020/3/26.
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
#import "SAIdentifier.h"
#import "SAConstants+Private.h"

static NSString *const kIDFV = @"$identity_idfv";
static NSString *const kAnonymousId = @"$identity_anonymous_id";

static NSString *const kLoginId = @"$identity_login_id";
static NSString *const kUUID = @"$identity_ios_uuid";
static NSString *const kLoginIdValue = @"newLoginId";

static NSString *const kMobile = @"mobile";
static NSString *const kMobileValue = @"131";

static NSString *const kEmail = @"email";
static NSString *const kEmailValue = @"qq.com";

static NSString *const kCustomKey = @"xyz";
static NSString *const kCustomValue = @"xyzValue";

static NSString *const kCookieId = @"$identity_cookie_id";
static NSString *const kCookieIdValue = @"xxx-cookie-id";

@interface SAIdentifierTest : XCTestCase

@property (nonatomic, strong) SAIdentifier *identifier;
@property (nonatomic, strong) dispatch_queue_t readWriteQueue;
@property (nonatomic, copy) NSString *deviceId;

@end

@implementation SAIdentifierTest

- (void)setUp {
    NSString *label = [NSString stringWithFormat:@"sensorsdata.readWriteQueue.%p", self];
    _readWriteQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
    _identifier = [[SAIdentifier alloc] initWithQueue:_readWriteQueue];
    [_identifier logout];
    _deviceId = _identifier.anonymousId;
}

- (void)tearDown {
    _identifier = nil;
    _deviceId = nil;
}

- (void)testAnonymousIdAfterIdentify {
    [_identifier identify:@"new_identifier"];
    XCTAssertTrue([_identifier.anonymousId isEqualToString:@"new_identifier"]);
}

- (void)testDistinctIdAfterIdentify {
    [_identifier identify:@"new_identifier"];
    XCTAssertTrue([_identifier.distinctId isEqualToString:@"new_identifier"]);
}

- (void)testAnonymousIdAfterIdentifyEmtpyString {
    [_identifier identify:@""];
    XCTAssertTrue([_identifier.anonymousId isEqualToString:_deviceId]);
}

- (void)testDistinctIdAfterIdentifyEmtpyString {
    [_identifier identify:@""];
    XCTAssertTrue([_identifier.distinctId isEqualToString:_deviceId]);
}

- (void)testAnonymousIdGreaterThanMaxLength {
    NSMutableString *str = [[NSMutableString alloc] initWithString:@""];
    for (int i = 0; i < kSAPropertyValueMaxLength + 5; i++) {
        [str appendString:@"a"];
    }
    [_identifier identify:str];
    XCTAssertTrue(_identifier.anonymousId.length == kSAPropertyValueMaxLength + 5);
}

- (void)testAnonymousIdLessThanMaxLength {
    NSMutableString *str = [[NSMutableString alloc] initWithString:@""];
    for (int i = 0; i < kSAPropertyValueMaxLength - 5; i++) {
        [str appendString:@"a"];
    }
    [_identifier identify:str];
    XCTAssertTrue(_identifier.anonymousId.length == kSAPropertyValueMaxLength - 5);
}

- (void)testLoginIdGreaterThanMaxLength {
    NSMutableString *str = [[NSMutableString alloc] initWithString:@""];
    for (int i = 0; i < kSAPropertyValueMaxLength + 5; i++) {
        [str appendString:@"a"];
    }
    XCTAssertTrue([_identifier isValidForLogin:kLoginId value:str]);
}

- (void)testLoginIdLessThanMaxLength {
    NSMutableString *str = [[NSMutableString alloc] initWithString:@""];
    for (int i = 0; i < kSAPropertyValueMaxLength - 5; i++) {
        [str appendString:@"a"];
    }
    XCTAssertTrue([_identifier isValidForLogin:kLoginId value:str]);
}

- (void)testLoginWithLoginId {
    [_identifier loginWithKey:kLoginId loginId:@"new_login_id"];
    XCTAssertFalse([_identifier isValidForLogin:kLoginId value:_identifier.loginId]);
}

- (void)testLoginWithAnonymousId {
    XCTAssertFalse([_identifier isValidForLogin:kLoginId value:_identifier.anonymousId]);
}

- (void)testLoginIdAfterLogin {
    [_identifier loginWithKey:kLoginId loginId:@"new_login_id"];
    XCTAssertTrue([_identifier.loginId isEqualToString:@"new_login_id"]);
}

- (void)testDistinctIdAfterLogin {
    [_identifier loginWithKey:kLoginId loginId:@"new_login_id"];
    XCTAssertTrue([_identifier.distinctId isEqualToString:@"new_login_id"]);
}

- (void)testLoginIdAfterLoginEmptyString {
    BOOL result = [_identifier isValidForLogin:kLoginId value:@""];
    XCTAssertFalse(result);
}

- (void)testDistinctIdAfterLoginEmptyString {
    [_identifier loginWithKey:kLoginId loginId:@""];
    XCTAssertTrue([_identifier.distinctId isEqualToString:_identifier.anonymousId]);
}

- (void)testResetAnonymousId {
    [_identifier resetAnonymousId];
    XCTAssertTrue([_identifier.anonymousId isEqualToString:[SAIdentifier hardwareID]]);
}

- (void)testLogout {
    [_identifier loginWithKey:kLoginId loginId:@"new_login_id"];
    [_identifier logout];
    XCTAssertNil(_identifier.loginId);
}

#pragma mark - identities - validation
- (void)testAddIdentityForInvalidKey {
    NSArray *array = @[@"111", @"date", kIDFV, kAnonymousId, kLoginId, kUUID, @{}, @"xcx###"];
    for (NSString *key in array) {
        BOOL result = [_identifier isValidForBind:key value:@""];
        XCTAssertFalse(result);
    }
}

- (void)testAddIdentityForValidKey {
    NSArray *array = @[@"xxx111", kMobile];
    for (NSString *key in array) {
        BOOL result = [_identifier isValidForBind:key value:@"value"];
        XCTAssertTrue(result);
    }
}

- (void)testAddIdentityForInvalidValue {
    [_identifier loginWithKey:kLoginId loginId:kLoginIdValue];
    NSArray *array = @[@"", kLoginIdValue, @{}];
    for (NSString *value in array) {
        BOOL result = [_identifier isValidForBind:kLoginId value:value];
        XCTAssertFalse(result);
    }
}

- (void)testAddIdentityForValidValue {
    [_identifier loginWithKey:kLoginId loginId:kLoginIdValue];
    NSArray *array = @[kCustomKey, @"newLoginId11"];
    for (NSString *value in array) {
        BOOL result = [_identifier isValidForBind:kCustomKey value:value];
        XCTAssertTrue(result);
    }
}

- (void)testRemoveIdentityForInvalidKey {
    NSArray *array = @[@"111", @"date", kIDFV, kAnonymousId, kLoginId, kUUID, @{}, @"xcx###"];
    for (NSString *key in array) {
        BOOL result = [_identifier isValidForBind:key value:@""];
        XCTAssertFalse(result);
    }
}

- (void)testRemoveIdentityForValidKey {
    NSArray *array = @[@"xxx111", kMobile, kEmail];
    for (NSString *key in array) {
        BOOL result = [_identifier isValidForBind:key value:@"value"];
        XCTAssertTrue(result);
    }
}

- (void)testRemoveIdentityForInvalidValue {
    [_identifier loginWithKey:kLoginId loginId:kLoginIdValue];
    NSArray *array = @[@"", kLoginIdValue, @{}];
    for (NSString *value in array) {
        BOOL result = [_identifier isValidForBind:kLoginId value:value];
        XCTAssertFalse(result);
    }
}

- (void)testRemoveIdentityForValidValue {
    [_identifier loginWithKey:kLoginId loginId:kLoginIdValue];
    NSArray *array = @[kCustomKey, @"newLoginId11"];
    for (NSString *value in array) {
        BOOL result = [_identifier isValidForBind:kCustomKey value:value];
        XCTAssertTrue(result);
    }
}

#pragma mark - identities - login & logout
- (void)testIdentitiesAfterLogin {
    [_identifier loginWithKey:kLoginId loginId:kLoginIdValue];
    XCTAssertTrue([_identifier.identities[kLoginId] isEqualToString:kLoginIdValue]);
}

- (void)testIdentitiesAfterLogout {
    [_identifier loginWithKey:kLoginId loginId:kLoginIdValue];
    [_identifier logout];
    XCTAssertNil(_identifier.identities[kLoginId]);
}

#pragma mark - identities - identify & reset
- (void)testIdentitiesAfterIdentify {
    NSString *newId = @"xxx-xxx-xxx";
    [_identifier identify:newId];
    XCTAssertTrue([_identifier.identities[kAnonymousId] isEqualToString:newId]);
}

- (void)testIdentitiesAfterResetAnonymousId {
    [_identifier resetAnonymousId];
    XCTAssertNil(_identifier.identities[kAnonymousId]);
}

- (void)testIdentitiesAfterIdentitfyAndReset {
    [_identifier identify:@"xxx-xxx-xxx-123"];
    [_identifier resetAnonymousId];
    XCTAssertNotNil(_identifier.identities[kAnonymousId]);
}

#pragma mark - identities - add
- (void)testAddIdentityForNormal {
    NSString *key = kCustomKey;
    NSString *value = kCustomValue;
    [_identifier bindIdentity:key value:value];
    XCTAssertTrue([_identifier.identities[key] isEqualToString:value]);
}


- (void)testAddIdentityForLogin {
    NSString *value = kCustomValue;
    [_identifier bindIdentity:kLoginId value:value];
    XCTAssertTrue([_identifier.identities[kLoginId] isEqualToString:value]);
}

- (void)testAddIdentityForDifferentLoginId {
    [_identifier loginWithKey:kLoginId loginId:kLoginIdValue];
    NSString *newId = @"xxxLoginId";
    [_identifier bindIdentity:kLoginId value:newId];
    XCTAssertTrue([_identifier.identities[kLoginId] isEqualToString:newId]);
}

#pragma mark - identities - remove
- (void)testRemoveIdentityForExist {
    NSString *key = kCustomKey;
    NSString *value = kCustomValue;
    [_identifier bindIdentity:key value:value];
    [_identifier unbindIdentity:key value:value];
    XCTAssertNil(_identifier.identities[key]);
}

- (void)testRemoveIdentityForNotExist {
    NSString *key = kCustomKey;
    NSString *value = kCustomValue;
    [_identifier unbindIdentity:key value:value];
    XCTAssertNil(_identifier.identities[key]);
}

- (void)testRemoveIdentityForDifferentValue {
    NSString *key = kCustomKey;
    NSString *value = kCustomValue;
    NSString *newValue = @"xxyyzzValue";
    [_identifier bindIdentity:key value:value];
    [_identifier unbindIdentity:key value:newValue];
    XCTAssertTrue([_identifier.identities[key] isEqualToString:value]);
}

#pragma mark - identities - event
- (void)testEventAfterLogout {

    [_identifier bindIdentity:kMobile value:kMobileValue];
    [_identifier bindIdentity:kEmail value:kEmailValue];
    [_identifier bindIdentity:kCustomKey value:kCustomValue];

    [_identifier logout];
    // 登录后事件
    XCTAssertTrue(_identifier.identities.allKeys.count == 1);
    XCTAssertNotNil(_identifier.identities[kIDFV]);
}

- (void)testEventAfterLogin {
    [_identifier bindIdentity:kMobile value:kMobileValue];
    [_identifier bindIdentity:kEmail value:kEmailValue];
    [_identifier bindIdentity:kCustomKey value:kCustomValue];

    [_identifier loginWithKey:kLoginId loginId:kLoginIdValue];
    // 登录事件
    NSDictionary *identities = [_identifier identitiesWithEventType:kSAEventTypeSignup];
    XCTAssertTrue(identities.allKeys.count == 5);
    XCTAssertTrue([identities[kMobile] isEqualToString:kMobileValue]);
    XCTAssertTrue([identities[kEmail] isEqualToString:kEmailValue]);
    XCTAssertTrue([identities[kLoginId] isEqualToString:kLoginIdValue]);
    XCTAssertTrue([identities[kCustomKey] isEqualToString:kCustomValue]);
    XCTAssertNotNil(identities[kIDFV]);

    // 登录后事件
    NSDictionary *after = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(after.allKeys.count == 2);
    XCTAssertTrue([after[kLoginId] isEqualToString:kLoginIdValue]);
    XCTAssertNotNil(after[kIDFV]);
}

- (void)testEventAfterBind {
    [_identifier bindIdentity:kMobile value:kMobileValue];
    [_identifier bindIdentity:kEmail value:kEmailValue];

    // 绑定事件
    NSDictionary *identities = [_identifier identitiesWithEventType:kSAEventTypeBind];
    XCTAssertTrue(identities.allKeys.count == 3);
    XCTAssertTrue([identities[kMobile] isEqualToString:kMobileValue]);
    XCTAssertTrue([identities[kEmail] isEqualToString:kEmailValue]);
    XCTAssertNotNil(identities[kIDFV]);

    // 绑定后事件
    NSDictionary *after = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(after.allKeys.count == 3);
    XCTAssertTrue([after[kMobile] isEqualToString:kMobileValue]);
    XCTAssertTrue([after[kEmail] isEqualToString:kEmailValue]);
    XCTAssertNotNil(after[kIDFV]);
}

- (void)testEventAfterUnbindForExistKey {
    [_identifier bindIdentity:kMobile value:kMobileValue];
    [_identifier bindIdentity:kEmail value:kEmailValue];

    [_identifier unbindIdentity:kEmail value:kEmailValue];
    // 解绑事件
    NSDictionary *identities = [_identifier identitiesWithEventType:kSAEventTypeUnbind];
    XCTAssertTrue(identities.allKeys.count == 1);
    XCTAssertTrue([identities[kEmail] isEqualToString:kEmailValue]);

    // 解绑后事件
    NSDictionary *after = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(after.allKeys.count == 2);
    XCTAssertTrue([after[kMobile] isEqualToString:kMobileValue]);
    XCTAssertNotNil(after[kIDFV]);
}

- (void)testEventAfterUnbindForNotExistKey {
    [_identifier bindIdentity:kMobile value:kMobileValue];
    [_identifier bindIdentity:kEmail value:kEmailValue];

    NSString *newEmail = @"163.com";
    [_identifier unbindIdentity:kEmail value:newEmail];
    // 解绑事件
    NSDictionary *identities = [_identifier identitiesWithEventType:kSAEventTypeUnbind];
    XCTAssertTrue(identities.allKeys.count == 1);
    XCTAssertTrue([identities[kEmail] isEqualToString:newEmail]);

    // 解绑后事件
    NSDictionary *after = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(after.allKeys.count == 3);
    XCTAssertTrue([after[kMobile] isEqualToString:kMobileValue]);
    XCTAssertTrue([after[kEmail] isEqualToString:kEmailValue]);
    XCTAssertNotNil(after[kIDFV]);
}

#pragma mark - H5 打通
- (void)testH5EventAfterUnbindForExist {
    [_identifier bindIdentity:kMobile value:kMobileValue];

    // H5 解绑事件
    NSDictionary *identities = [_identifier mergeH5Identities:@{kMobile:kMobileValue} eventType:kSAEventTypeUnbind];
    XCTAssertTrue(identities.allKeys.count == 1);
    XCTAssertTrue([identities[kMobile] isEqualToString:kMobileValue]);

    // H5 解绑后事件
    NSDictionary *after = [_identifier mergeH5Identities:@{kCookieId:kCookieIdValue, kEmail:kEmailValue} eventType:kSAEventTypeTrack];
    XCTAssertTrue(after.allKeys.count == 3);
    XCTAssertTrue([after[kEmail] isEqualToString:kEmailValue]);
    XCTAssertNotNil(after[kIDFV]);
    XCTAssertNotNil(after[kCookieId]);
    // Native 解绑后事件
    NSDictionary *native = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(native.allKeys.count == 1);
    XCTAssertNotNil(native[kIDFV]);
}

- (void)testH5EventAfterUnbindForNotExist {
    NSString *existValue = kMobileValue;
    [_identifier bindIdentity:kMobile value:existValue];

    // H5 解绑事件
    NSString *unbindValue = @"151";
    NSDictionary *identities = [_identifier mergeH5Identities:@{kMobile:unbindValue} eventType:kSAEventTypeUnbind];
    XCTAssertTrue(identities.allKeys.count == 1);
    XCTAssertTrue([identities[kMobile] isEqualToString:unbindValue]);

    // H5 解绑后事件
    NSDictionary *after = [_identifier mergeH5Identities:@{kCookieId:kCookieIdValue, kEmail:kEmailValue} eventType:kSAEventTypeTrack];
    XCTAssertTrue(after.allKeys.count == 4);
    XCTAssertTrue([after[kEmail] isEqualToString:kEmailValue]);
    XCTAssertTrue([after[kMobile] isEqualToString:existValue]);
    XCTAssertNotNil(after[kIDFV]);
    XCTAssertNotNil(after[kCookieId]);

    // Native 解绑后事件
    NSDictionary *native = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(native.allKeys.count == 2);
    XCTAssertTrue([native[kMobile] isEqualToString:existValue]);
    XCTAssertNotNil(native[kIDFV]);
}

- (void)testH5EventAfterBindForNewKey {
    NSString *bindValue = kMobileValue;
    NSDictionary *identities = [_identifier mergeH5Identities:@{kMobile: bindValue} eventType:kSAEventTypeBind];
    // H5 绑定事件
    XCTAssertTrue(identities.allKeys.count == 2);
    XCTAssertTrue([identities[kMobile] isEqualToString:bindValue]);
    XCTAssertNotNil(identities[kIDFV]);

    // H5 绑定后事件
    NSDictionary *after = [_identifier mergeH5Identities:@{kCookieId:kCookieIdValue, kEmail:kEmailValue} eventType:kSAEventTypeTrack];
    XCTAssertTrue(after.allKeys.count == 4);
    XCTAssertTrue([after[kMobile] isEqualToString:bindValue]);
    XCTAssertTrue([after[kEmail] isEqualToString:kEmailValue]);
    XCTAssertNotNil(after[kIDFV]);
    XCTAssertNotNil(after[kCookieId]);

    // Native 绑定后事件
    NSDictionary *native = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(native.allKeys.count == 2);
    XCTAssertTrue([native[kMobile] isEqualToString:bindValue]);
    XCTAssertNotNil(native[kIDFV]);
}

- (void)testH5EventAfterBindForExistKey {
    NSString *oldValue = kMobileValue;
    [_identifier bindIdentity:kMobile value:oldValue];

    // H5 绑定事件
    NSString *newValue = @"151";
    NSDictionary *identities = [_identifier mergeH5Identities:@{kMobile: newValue} eventType:kSAEventTypeBind];
    XCTAssertTrue(identities.allKeys.count == 2);
    XCTAssertTrue([identities[kMobile] isEqualToString:oldValue]);
    XCTAssertNotNil(identities[kIDFV]);

    // H5 绑定后事件
    NSDictionary *after = [_identifier mergeH5Identities:@{kCookieId:kCookieIdValue, kEmail:kEmailValue} eventType:kSAEventTypeTrack];
    XCTAssertTrue(after.allKeys.count == 4);
    XCTAssertTrue([after[kMobile] isEqualToString:oldValue]);
    XCTAssertTrue([after[kEmail] isEqualToString:kEmailValue]);
    XCTAssertNotNil(after[kIDFV]);
    XCTAssertNotNil(after[kCookieId]);

    // Native 绑定后事件
    NSDictionary *native = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(native.allKeys.count == 2);
    XCTAssertTrue([native[kMobile] isEqualToString:oldValue]);
    XCTAssertNotNil(native[kIDFV]);
}

- (void)testH5EventAfterSignUpForNotSign {
    // H5 登录事件
    [_identifier loginWithKey:kLoginId loginId:kLoginIdValue];
    NSDictionary *identities = [_identifier mergeH5Identities:@{kLoginId:kLoginIdValue} eventType:kSAEventTypeSignup];
    XCTAssertTrue(identities.allKeys.count == 2);
    XCTAssertTrue([identities[kLoginId] isEqualToString:kLoginIdValue]);
    XCTAssertNotNil(identities[kIDFV]);

    // H5 登录后事件
    NSDictionary *after = [_identifier mergeH5Identities:@{kCookieId:kCookieIdValue, kEmail:kEmailValue} eventType:kSAEventTypeTrack];
    XCTAssertTrue(after.allKeys.count == 4);
    XCTAssertTrue([after[kLoginId] isEqualToString:kLoginIdValue]);
    XCTAssertTrue([after[kEmail] isEqualToString:kEmailValue]);
    XCTAssertNotNil(after[kIDFV]);
    XCTAssertNotNil(after[kCookieId]);

    // Native 登录后事件
    NSDictionary *native = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(native.allKeys.count == 2);
    XCTAssertTrue([native[kLoginId] isEqualToString:kLoginIdValue]);
    XCTAssertNotNil(native[kIDFV]);
}

- (void)testH5EventAfterSignUpForSigned {
    NSString *oldValue = kLoginIdValue;
    NSString *newValue = @"xxxNewLoginId";
    [_identifier loginWithKey:kLoginId loginId:oldValue];
    // H5 登录事件

    [_identifier loginWithKey:kLoginId loginId:newValue];
    NSDictionary *identities = [_identifier mergeH5Identities:@{kLoginId:newValue} eventType:kSAEventTypeSignup];
    XCTAssertTrue(identities.allKeys.count == 2);
    XCTAssertTrue([identities[kLoginId] isEqualToString:newValue]);
    XCTAssertNotNil(identities[kIDFV]);

    // H5 登录后事件
    NSDictionary *after = [_identifier mergeH5Identities:@{kCookieId:kCookieIdValue, kEmail:kEmailValue} eventType:kSAEventTypeTrack];
    XCTAssertTrue(after.allKeys.count == 4);
    XCTAssertTrue([after[kLoginId] isEqualToString:newValue]);
    XCTAssertTrue([after[kEmail] isEqualToString:kEmailValue]);
    XCTAssertNotNil(after[kIDFV]);
    XCTAssertNotNil(after[kCookieId]);

    // Native 登录后事件
    NSDictionary *native = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(native.allKeys.count == 2);
    XCTAssertTrue([native[kLoginId] isEqualToString:newValue]);
    XCTAssertNotNil(native[kIDFV]);
}

- (void)testH5EventAfterNativeSignUpAndBind {
    [_identifier loginWithKey:kLoginId loginId:kLoginId];
    [_identifier bindIdentity:kCustomKey value:kCustomValue];

    // H5 事件
    NSDictionary *identities = [_identifier mergeH5Identities:@{kCookieId:kCookieIdValue} eventType:kSAEventTypeTrack];
    XCTAssertTrue(identities.allKeys.count == 4);
    XCTAssertTrue([identities[kLoginId] isEqualToString:kLoginId]);
    XCTAssertTrue([identities[kCustomKey] isEqualToString:kCustomValue]);
    XCTAssertNotNil(identities[kIDFV]);
    XCTAssertNotNil(identities[kCookieId]);

    // Native 事件
    NSDictionary *native = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(native.allKeys.count == 3);
    XCTAssertTrue([native[kLoginId] isEqualToString:kLoginId]);
    XCTAssertTrue([native[kCustomKey] isEqualToString:kCustomValue]);
    XCTAssertNotNil(native[kIDFV]);
}

- (void)testH5EventForNativeInitial {
    // H5 事件
    NSDictionary *h5Dic = @{kCookieId:kCookieIdValue, kMobile:kMobileValue, kEmail:kEmailValue};
    NSDictionary *identities = [_identifier mergeH5Identities:h5Dic eventType:kSAEventTypeTrack];
    XCTAssertTrue(identities.allKeys.count == 4);
    XCTAssertTrue([identities[kMobile] isEqualToString:kMobileValue]);
    XCTAssertTrue([identities[kEmail] isEqualToString:kEmailValue]);
    XCTAssertNotNil(identities[kIDFV]);
    XCTAssertNotNil(identities[kCookieId]);

    // Native 事件
    NSDictionary *native = [_identifier identitiesWithEventType:kSAEventTypeTrack];
    XCTAssertTrue(native.allKeys.count == 1);
    XCTAssertNotNil(native[kIDFV]);
}

@end
