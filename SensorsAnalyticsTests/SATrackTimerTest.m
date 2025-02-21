//
// SATrackTimerTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/27.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SATrackTimer.h"

#define second(x) (x * 1000)

@interface SATrackTimerTest : XCTestCase

@property (nonatomic, strong) SATrackTimer *trackTimer;

@end

@implementation SATrackTimerTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.trackTimer = [[SATrackTimer alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (NSString *)simulateTrackTimerStart:(NSString *)event currentSysUpTime:(UInt64)currentSysUpTime {
    NSString *eventId = [self.trackTimer generateEventIdByEventName:event];
    [self.trackTimer trackTimerStart:eventId currentSysUpTime:currentSysUpTime];
    return eventId;
}

- (void)testGenerateEventIdByEmptyEventName {
    NSString *eventId = [self.trackTimer generateEventIdByEventName:@""];
    XCTAssertTrue([eventId isEqualToString:@""]);
}

- (void)testGenerateEventIdByNilEventName {
    NSString *eventName = nil;
    XCTAssertNil([self.trackTimer generateEventIdByEventName:eventName]);
}

- (void)testGenerateEventIdByNotStringEventName {
//   NSString *eventName = (NSString *)@[@1, @2];
//   XCTAssertNil([self.trackTimer generateEventIdByEventName:eventName]);
}

- (void)testGenerateEventIdByStringEventName {
    NSString *eventId = [self.trackTimer generateEventIdByEventName:@"eventName"];
    XCTAssertTrue([eventId hasPrefix:@"eventName"]);
}

- (void)testEventNameFromEmptyEventId {
    NSString *eventName = [self.trackTimer eventNameFromEventId:@""];
    XCTAssertTrue([eventName isEqualToString:@""]);
}

- (void)testEventNameFromNilEventId {
    NSString *eventId = nil;
    XCTAssertNil([self.trackTimer eventNameFromEventId:eventId]);
}

- (void)testEventNameFromNotStringEventId {
//   NSString *eventId = (NSString *)@[@1, @2];
//   XCTAssertNil([self.trackTimer eventNameFromEventId:eventId]);
}

- (void)testEventNameFromNoSuffixEventId {
    NSString *eventName = [self.trackTimer eventNameFromEventId:@"eventId"];
    XCTAssertTrue([eventName isEqualToString:@"eventId"]);
}

- (void)testEventNameFromSuffixEventId {
    NSString *eventName = [self.trackTimer eventNameFromEventId:@"eventId_D3AC265B_3CC2_4C45_B8F0_3E05A83A9DAE_SATimer"];
    XCTAssertTrue([eventName isEqualToString:@"eventId"]);
}

#pragma mark - normal timer
- (void)testNormalTimerEventDuration {
    NSString *eventName = @"testTimer1";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer trackTimerPause:eventName currentSysUpTime:second(4)];
    [self.trackTimer trackTimerResume:eventName currentSysUpTime:second(6)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventName currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 4, 0.1);
}

- (void)testNormalTimerEnterBackgroundAndBecomeActive {
    NSString *eventName = @"testTimer2";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer trackTimerPause:eventName currentSysUpTime:second(4)];
    [self.trackTimer pauseAllEventTimers:second(6)];
    [self.trackTimer resumeAllEventTimers:second(8)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventName currentSysUpTime:second(10)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testNormalTimerEnterBackgroundAndBecomeActive2 {
    NSString *eventName = @"testTimer3";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer pauseAllEventTimers:second(4)];
    [self.trackTimer resumeAllEventTimers:second(6)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventName currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 4, 0.1);
}

- (void)testNormalTimerMutipleInvokeStart {
    NSString *eventName = @"testTimer4";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(4)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventName currentSysUpTime:second(6)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testNormalTimerMutipleInvokePause {
    NSString *eventName = @"testTimer5";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer trackTimerPause:eventName currentSysUpTime:second(4)];
    [self.trackTimer trackTimerPause:eventName currentSysUpTime:second(6)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventName currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testNormalTimerMutipleInvokeResume {
    NSString *eventName = @"testTimer6";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer trackTimerPause:eventName currentSysUpTime:second(4)];
    [self.trackTimer trackTimerResume:eventName currentSysUpTime:second(6)];
    [self.trackTimer trackTimerResume:eventName currentSysUpTime:second(8)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventName currentSysUpTime:second(10)];
    XCTAssertEqualWithAccuracy([duration floatValue], 6, 0.1);
}

- (void)testNormalTimerMutipleInvokeEnd {
    NSString *eventName = @"testTimer7";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventName currentSysUpTime:second(4)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
    NSNumber *duration1 = [self.trackTimer eventDurationFromEventId:eventName currentSysUpTime:second(6)];
    XCTAssertNil(duration1);
}

- (void)testNormalTimerClearEvents {
    NSString *eventName = @"testTimer8";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer clearAllEventTimers];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventName currentSysUpTime:second(4)];
    XCTAssertNil(duration);
    NSString *originalEventName = [self.trackTimer eventNameFromEventId:eventName];
    XCTAssertTrue([originalEventName isEqualToString:eventName]);
}

#pragma mark - hybrid timer
- (void)testHybridTimer {
    NSString *eventName = @"testTimer9";
    [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];

    [self.trackTimer trackTimerPause:eventName currentSysUpTime:second(4)];
    [self.trackTimer trackTimerPause:eventId currentSysUpTime:second(4)];

    [self.trackTimer trackTimerResume:eventName currentSysUpTime:second(6)];
    [self.trackTimer trackTimerResume:eventId currentSysUpTime:second(6)];

    NSNumber *duration1 = [self.trackTimer eventDurationFromEventId:eventName currentSysUpTime:second(8)];
    NSNumber *duration2 = [self.trackTimer eventDurationFromEventId:eventId currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration1 floatValue], 4, 0.1);
    XCTAssertEqualWithAccuracy([duration2 floatValue], 4, 0.1);
}

#pragma mark - cross timer
- (void)testCrossTimerEventDuration {
    NSString *eventName = @"testTimer10";
    NSString *eventId1 = [self simulateTrackTimerStart:eventName currentSysUpTime:second(1)];
    NSString *eventId2 = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer trackTimerPause:eventId1 currentSysUpTime:second(3)];
    [self.trackTimer trackTimerPause:eventId2 currentSysUpTime:second(4)];
    [self.trackTimer trackTimerResume:eventId1 currentSysUpTime:second(5)];
    [self.trackTimer trackTimerResume:eventId2 currentSysUpTime:second(6)];
    NSNumber *duration1 = [self.trackTimer eventDurationFromEventId:eventId1 currentSysUpTime:second(7)];
    NSNumber *duration2 = [self.trackTimer eventDurationFromEventId:eventId2 currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration1 floatValue], 4, 0.1);
    XCTAssertEqualWithAccuracy([duration2 floatValue], 4, 0.1);

    XCTAssertTrue([[self.trackTimer eventNameFromEventId:eventId1] isEqualToString:eventName]);
    XCTAssertTrue([[self.trackTimer eventNameFromEventId:eventId2] isEqualToString:eventName]);
}

- (void)testCrossTimerEnterBackgroundAndBecomeActive {
    NSString *eventName = @"testTimer11";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer trackTimerPause:eventId currentSysUpTime:second(4)];
    [self.trackTimer pauseAllEventTimers:second(6)];
    [self.trackTimer resumeAllEventTimers:second(8)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventId currentSysUpTime:second(10)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testCrossTimerEnterBackgroundAndBecomeActive2 {
    NSString *eventName = @"testTimer12";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer pauseAllEventTimers:second(4)];
    [self.trackTimer resumeAllEventTimers:second(6)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventId currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 4, 0.1);
}
- (void)testCrossTimerClearEvents {
    NSString *eventName = @"testTimer13";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer clearAllEventTimers];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventId currentSysUpTime:second(4)];
    XCTAssertNil(duration);
    NSString *originalEventName = [self.trackTimer eventNameFromEventId:eventId];
    XCTAssertTrue([originalEventName isEqualToString:eventName]);
}

- (void)testCrossTimerMutipleInvokeStart {
    NSString *eventName = @"testTimer14";
    NSString *eventId1 = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    NSString *eventId2 = [self simulateTrackTimerStart:eventName currentSysUpTime:second(4)];
    NSNumber *duration1 = [self.trackTimer eventDurationFromEventId:eventId1 currentSysUpTime:second(6)];
    XCTAssertEqualWithAccuracy([duration1 floatValue], 4, 0.1);
    NSNumber *duration2 = [self.trackTimer eventDurationFromEventId:eventId2 currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration2 floatValue], 4, 0.1);
}

- (void)testCrossTimerMutipleInvokePause {
    NSString *eventName = @"testTimer15";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer trackTimerPause:eventId currentSysUpTime:second(4)];
    [self.trackTimer trackTimerPause:eventId currentSysUpTime:second(6)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventId currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testCrossTimerMutipleInvokeResume {
    NSString *eventName = @"testTimer16";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    [self.trackTimer trackTimerPause:eventId currentSysUpTime:second(4)];
    [self.trackTimer trackTimerResume:eventId currentSysUpTime:second(6)];
    [self.trackTimer trackTimerResume:eventId currentSysUpTime:second(8)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventId currentSysUpTime:second(10)];
    XCTAssertEqualWithAccuracy([duration floatValue], 6, 0.1);
}

- (void)testCrossTimerMutipleInvokeEnd {
    NSString *eventName = @"testTimer17";
    NSString *eventId = [self simulateTrackTimerStart:eventName currentSysUpTime:second(2)];
    NSNumber *duration = [self.trackTimer eventDurationFromEventId:eventId currentSysUpTime:second(4)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
    NSNumber *duration1 = [self.trackTimer eventDurationFromEventId:eventId currentSysUpTime:second(6)];
    XCTAssertNil(duration1);
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
