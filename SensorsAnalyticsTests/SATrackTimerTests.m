//
// SATrackTimerTests.m
// SensorsAnalyticsTests
//
// Created by 彭远洋 on 2020/1/3.
// Copyright © 2020 SensorsData. All rights reserved.
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
#import "SATrackTimer.h"

#define second(x) (x * 1000)

@interface SATrackTimerTests : XCTestCase

@property (nonatomic, strong) SATrackTimer *timer;

@end

@implementation SATrackTimerTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _timer = [[SATrackTimer alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (NSString *)simulateTrackTimerStart:(NSString *)event currentSysUpTime:(UInt64)currentSysUpTime {
    NSString *eventId = [_timer generateEventIdByEventName:event];
    [_timer trackTimerStart:eventId currentSysUpTime:currentSysUpTime];
    return eventId;
}

#pragma mark - normal timer
- (void)testNormalTimerEventDuration {
    NSString *eventName = @"testTimer1";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventName currentSysUpTime:second(4)];
    [_timer trackTimerResume:eventName currentSysUpTime:second(6)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 4, 0.1);
}

- (void)testNormalTimerEnterBackgroundAndBecomeActive {
    NSString *eventName = @"testTimer2";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventName currentSysUpTime:second(4)];
    [_timer pauseAllEventTimers:second(6)];
    [_timer resumeAllEventTimers:second(8)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(10)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testNormalTimerEnterBackgroundAndBecomeActive2 {
    NSString *eventName = @"testTimer3";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer pauseAllEventTimers:second(4)];
    [_timer resumeAllEventTimers:second(6)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 4, 0.1);
}

- (void)testNormalTimerMutipleInvokeStart {
    NSString *eventName = @"testTimer4";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(4)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(6)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testNormalTimerMutipleInvokePause {
    NSString *eventName = @"testTimer5";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventName currentSysUpTime:second(4)];
    [_timer trackTimerPause:eventName currentSysUpTime:second(6)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testNormalTimerMutipleInvokeResume {
    NSString *eventName = @"testTimer6";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventName currentSysUpTime:second(4)];
    [_timer trackTimerResume:eventName currentSysUpTime:second(6)];
    [_timer trackTimerResume:eventName currentSysUpTime:second(8)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(10)];
    XCTAssertEqualWithAccuracy([duration floatValue], 6, 0.1);
}

- (void)testNormalTimerMutipleInvokeEnd {
    NSString *eventName = @"testTimer7";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(4)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
    NSNumber *duration1 = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(6)];
    XCTAssertNil(duration1);
}

- (void)testNormalTimerClearEvents {
    NSString *eventName = @"testTimer8";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer clearAllEventTimers];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(4)];
    XCTAssertNil(duration);
    NSString *originalEventName = [_timer eventNameFromEventId:eventName];
    XCTAssertTrue([originalEventName isEqualToString:eventName]);
}

#pragma mark - hybrid timer
- (void)testHybridTimer {
    NSString *eventName = @"testTimer9";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];

    [_timer trackTimerPause:eventName currentSysUpTime:second(4)];
    [_timer trackTimerPause:eventId currentSysUpTime:second(4)];

    [_timer trackTimerResume:eventName currentSysUpTime:second(6)];
    [_timer trackTimerResume:eventId currentSysUpTime:second(6)];

    NSNumber *duration1 = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(8)];
    NSNumber *duration2 = [_timer eventDurationFromEventId:eventId currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration1 floatValue], 4, 0.1);
    XCTAssertEqualWithAccuracy([duration2 floatValue], 4, 0.1);
}

#pragma mark - cross timer
- (void)testCrossTimerEventDuration {
    NSString *eventName = @"testTimer10";
    NSString *eventId1 = [self simulateTrackTimerStart:eventName currentSysUpTime:second(1)];
    NSString *eventId2 = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventId1 currentSysUpTime:second(3)];
    [_timer trackTimerPause:eventId2 currentSysUpTime:second(4)];
    [_timer trackTimerResume:eventId1 currentSysUpTime:second(5)];
    [_timer trackTimerResume:eventId2 currentSysUpTime:second(6)];
    NSNumber *duration1 = [_timer eventDurationFromEventId:eventId1 currentSysUpTime:second(7)];
    NSNumber *duration2 = [_timer eventDurationFromEventId:eventId2 currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration1 floatValue], 4, 0.1);
    XCTAssertEqualWithAccuracy([duration2 floatValue], 4, 0.1);

    XCTAssertTrue([[_timer eventNameFromEventId:eventId1] isEqualToString:eventName]);
    XCTAssertTrue([[_timer eventNameFromEventId:eventId2] isEqualToString:eventName]);
}

- (void)testCrossTimerEnterBackgroundAndBecomeActive {
    NSString *eventName = @"testTimer11";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventId currentSysUpTime:second(4)];
    [_timer pauseAllEventTimers:second(6)];
    [_timer resumeAllEventTimers:second(8)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventId currentSysUpTime:second(10)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testCrossTimerEnterBackgroundAndBecomeActive2 {
    NSString *eventName = @"testTimer12";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer pauseAllEventTimers:second(4)];
    [_timer resumeAllEventTimers:second(6)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventId currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 4, 0.1);
}
- (void)testCrossTimerClearEvents {
    NSString *eventName = @"testTimer13";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer clearAllEventTimers];
    NSNumber *duration = [_timer eventDurationFromEventId:eventId currentSysUpTime:second(4)];
    XCTAssertNil(duration);
    NSString *originalEventName = [_timer eventNameFromEventId:eventId];
    XCTAssertTrue([originalEventName isEqualToString:eventName]);
}

- (void)testCrossTimerMutipleInvokeStart {
    NSString *eventName = @"testTimer14";
    NSString *eventId1 = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    NSString *eventId2 = [self simulateTrackTimerStart:eventName currentSysUpTime:second(4)];
    NSNumber *duration1 = [_timer eventDurationFromEventId:eventId1 currentSysUpTime:second(6)];
    XCTAssertEqualWithAccuracy([duration1 floatValue], 4, 0.1);
    NSNumber *duration2 = [_timer eventDurationFromEventId:eventId2 currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration2 floatValue], 4, 0.1);
}

- (void)testCrossTimerMutipleInvokePause {
    NSString *eventName = @"testTimer15";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventId currentSysUpTime:second(4)];
    [_timer trackTimerPause:eventId currentSysUpTime:second(6)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventId currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testCrossTimerMutipleInvokeResume {
    NSString *eventName = @"testTimer16";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventId currentSysUpTime:second(4)];
    [_timer trackTimerResume:eventId currentSysUpTime:second(6)];
    [_timer trackTimerResume:eventId currentSysUpTime:second(8)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventId currentSysUpTime:second(10)];
    XCTAssertEqualWithAccuracy([duration floatValue], 6, 0.1);
}

- (void)testCrossTimerMutipleInvokeEnd {
    NSString *eventName = @"testTimer17";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventId currentSysUpTime:second(4)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
    NSNumber *duration1 = [_timer eventDurationFromEventId:eventId currentSysUpTime:second(6)];
    XCTAssertNil(duration1);
}

@end
