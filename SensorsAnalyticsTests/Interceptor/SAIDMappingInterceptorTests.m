//
// SAIDMappingInterceptorTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2022/4/21.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SAIDMappingInterceptor.h"
#import "SATrackEventObject.h"
#import "SAIdentifier.h"

@interface SAIDMappingInterceptorTests : XCTestCase

@property (nonatomic, strong) SAFlowData *input;
@property (nonatomic, strong) SAIDMappingInterceptor *interceptor;

@property (nonatomic, strong) SAIdentifier *identifier;

@end

@implementation SAIDMappingInterceptorTests

- (void)setUp {
    self.input = [[SAFlowData alloc] init];
    self.interceptor = [SAIDMappingInterceptor interceptorWithParam:nil];

    dispatch_queue_t queue = dispatch_queue_create("com.sensorsdata.SAIDMappingInterceptorTests", DISPATCH_QUEUE_SERIAL);
    self.identifier = [[SAIdentifier alloc] initWithQueue:queue];
    self.input.identifier = self.identifier;
}

- (void)tearDown {
    self.input = nil;
    self.interceptor = nil;
    self.identifier = nil;
}

- (void)testDistinctID {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@"123"];
    self.input.eventObject = object;

    [self.interceptor processWithInput:self.input completion:^(SAFlowData * _Nonnull output) {
        SABaseEventObject *object = output.eventObject;
        XCTAssertTrue([object.distinctId isEqualToString:self.identifier.distinctId]);
    }];
}

- (void)testAnonymousID {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@"123"];
    self.input.eventObject = object;

    [self.interceptor processWithInput:self.input completion:^(SAFlowData * _Nonnull output) {
        SABaseEventObject *object = output.eventObject;
        XCTAssertTrue([object.anonymousId isEqualToString:self.identifier.anonymousId]);
    }];
}

- (void)testLoginID {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@"123"];
    self.input.eventObject = object;

    [self.identifier loginWithKey:kSAIdentitiesLoginId loginId:@"123"];

    [self.interceptor processWithInput:self.input completion:^(SAFlowData * _Nonnull output) {
        SABaseEventObject *object = output.eventObject;
        XCTAssertTrue([object.loginId isEqualToString:self.identifier.loginId]);
    }];
}

@end
