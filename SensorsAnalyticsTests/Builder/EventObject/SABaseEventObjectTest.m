//
// SABaseEventObjectTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/22.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SABaseEventObject.h"
#import "SensorsAnalyticsSDK.h"

@interface SABaseEventObjectTest : XCTestCase

@property (nonatomic, strong) NSDictionary *h5Event;

@end

@implementation SABaseEventObjectTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0" launchOptions:nil];
    options.autoTrackEventType = SensorsAnalyticsEventTypeAppStart | SensorsAnalyticsEventTypeAppEnd | SensorsAnalyticsEventTypeAppClick | SensorsAnalyticsEventTypeAppViewScreen;
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testIsSignUpWithEmptyEventId {
    SABaseEventObject *baseEventObject = [[SABaseEventObject alloc] init];
    baseEventObject.eventId = @"";
    XCTAssertFalse([baseEventObject isSignUp]);
}

- (void)testIsSignUpWithNilEventId {
    SABaseEventObject *baseEventObject = [[SABaseEventObject alloc] init];
    NSString *eventId = nil;
    baseEventObject.eventId = eventId;
    XCTAssertFalse([baseEventObject isSignUp]);
}

- (void)testIsSignUpWithNotStringEventId {
    SABaseEventObject *baseEventObject = [[SABaseEventObject alloc] init];
    NSString *eventId = (NSString *)@1;
    baseEventObject.eventId = eventId;
    XCTAssertFalse([baseEventObject isSignUp]);
}

- (void)testIsSignUpWithStringEventId {
    SABaseEventObject *baseEventObject = [[SABaseEventObject alloc] init];
    baseEventObject.eventId = @"ABC";
    XCTAssertFalse([baseEventObject isSignUp]);
}

- (void)testJsonObjectWithEmptyEventId {
    SABaseEventObject *baseEventObject = [[SABaseEventObject alloc] init];
    baseEventObject.eventId = @"";
    NSDictionary *jsonObject = [baseEventObject jsonObject];
    XCTAssertTrue([jsonObject isKindOfClass:[NSDictionary class]]);
    XCTAssertGreaterThan(jsonObject.count, 0);
    XCTAssertTrue([jsonObject[@"event"] isEqualToString:@""]);
}

- (void)testJsonObjectWithNilEventId {
    SABaseEventObject *baseEventObject = [[SABaseEventObject alloc] init];
    NSString *eventId = nil;
    baseEventObject.eventId = eventId;
    NSDictionary *jsonObject = [baseEventObject jsonObject];
    XCTAssertTrue([jsonObject isKindOfClass:[NSDictionary class]]);
    XCTAssertGreaterThan(jsonObject.count, 0);
    XCTAssertNil(jsonObject[@"event"]);
}

- (void)testJsonObjectWithNotStringEventId {
//   SABaseEventObject *baseEventObject = [[SABaseEventObject alloc] init];
//   NSString *eventId = (NSString *)@1;
//   baseEventObject.eventId = eventId;
//   NSDictionary *jsonObject = [baseEventObject jsonObject];
//   XCTAssertTrue([jsonObject isKindOfClass:[NSDictionary class]]);
//   XCTAssertGreaterThan(jsonObject.count, 0);
//   XCTAssertNil(jsonObject[@"event"]);
}

- (void)testJsonObjectWithStringEventId {
    SABaseEventObject *baseEventObject = [[SABaseEventObject alloc] init];
    baseEventObject.eventId = @"ABC";
    NSDictionary *jsonObject = [baseEventObject jsonObject];
    XCTAssertTrue([jsonObject isKindOfClass:[NSDictionary class]]);
    XCTAssertGreaterThan(jsonObject.count, 0);
    XCTAssertTrue([jsonObject[@"event"] isEqualToString:@"ABC"]);
}

@end
