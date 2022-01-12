//
// SensorsAnalyticsTest.m
// SensorsAnalyticsTest
//
// Created by 张敏超 on 2019/3/12.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <XCTest/XCTest.h>
#import "SAConfigOptions.h"
#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsSDK+Private.h"

@interface SensorsAnalyticsTest : XCTestCase

@end

@implementation SensorsAnalyticsTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0" launchOptions:nil];
    options.autoTrackEventType = SensorsAnalyticsEventTypeAppStart | SensorsAnalyticsEventTypeAppEnd | SensorsAnalyticsEventTypeAppClick | SensorsAnalyticsEventTypeAppViewScreen;
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

// 调用 Profile 相关的方法时，事件名称为 nil，不调用 callback
- (void)testProfileEventWithoutCallback {
    __block BOOL isTrackEventCallbackExecuted = NO;
    [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL(NSString * _Nonnull eventName, NSMutableDictionary<NSString *,id> * _Nonnull properties) {
        isTrackEventCallbackExecuted = YES;
        return YES;
    }];
    [[SensorsAnalyticsSDK sharedInstance] set:@"avatar_url" to:@"http://www.sensorsdata.cn"];
    sleep(0.5);
    XCTAssertFalse(isTrackEventCallbackExecuted);
}

#pragma mark - event
//测试 itemSet 接口，是否成功
- (void)testItemSet {
//   XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
//   
//   dispatch_queue_t queue = dispatch_queue_create("sensorsData-Test", DISPATCH_QUEUE_SERIAL);
//   dispatch_async(queue, ^{
//       
//       NSInteger lastCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
//       [[SensorsAnalyticsSDK sharedInstance] itemSetWithType:@"itemSet0517" itemId:@"itemId0517" properties:@{@"itemSet":@"acsdfgvzscd"}];
//       
//       sleep(1);
//       
//       NSInteger newCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
//       BOOL insertSucceed = newCount == lastCount + 1;
//       XCTAssertTrue(insertSucceed);
//       
//       [expectation fulfill];
//   });
//   
//   [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
//       XCTAssertNil(error);
//   }];
}

//测试 itemDelete 接口，是否成功
- (void)testItemDelete {
//   XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
//
//   dispatch_queue_t queue = dispatch_queue_create("sensorsData-Test", DISPATCH_QUEUE_SERIAL);
//   dispatch_async(queue, ^{
//       NSInteger lastCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
//       [[SensorsAnalyticsSDK sharedInstance] itemDeleteWithType:@"itemSet0517" itemId:@"itemId0517"];
//
//       sleep(1);
//
//       NSInteger newCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
//       BOOL insertSucceed = newCount == lastCount + 1;
//       XCTAssertTrue(insertSucceed);
//
//       [expectation fulfill];
//   });
//
//   [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
//       XCTAssertNil(error);
//   }];
}

#pragma mark - trackTimer
///测试是否开启事件计时
- (void)testShouldTrackTimerStart {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    
    dispatch_queue_t queue = dispatch_queue_create("sensorsData-Test", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        
        [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
            if ([eventName isEqualToString:@"timerEvent"]) {
                
                NSDictionary *callBackProperties = properties;
                BOOL isContainsDuration = [callBackProperties.allKeys containsObject:@"event_duration"];
                XCTAssertTrue(isContainsDuration);
                
                [expectation fulfill];
            }
            return YES;
        }];
        
        [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"timerEvent"];
        sleep(1);
        [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"timerEvent"];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
         XCTAssertNil(error);
    }];
}

/// 测试事件计时暂停
- (void)testTrackTimerPause {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    
    dispatch_queue_t queue = dispatch_queue_create("sensorsData-Test", DISPATCH_QUEUE_SERIAL);

    [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"timerEvent"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), queue, ^{
        [[SensorsAnalyticsSDK sharedInstance] trackTimerPause:@"timerEvent"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), queue, ^{
        [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"timerEvent"];
    });
    [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
        if ([eventName isEqualToString:@"timerEvent"]) {
            XCTAssertEqualWithAccuracy([properties[@"event_duration"] floatValue], 1.5, 0.1);

            [expectation fulfill];
        }
        return NO;
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

/// 测试事件计时暂停后恢复
- (void)testTrackTimerResume {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];

    dispatch_queue_t queue = dispatch_queue_create("sensorsData-Test", DISPATCH_QUEUE_SERIAL);

    [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"timerEvent"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), queue, ^{
        [[SensorsAnalyticsSDK sharedInstance] trackTimerPause:@"timerEvent"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), queue, ^{
        [[SensorsAnalyticsSDK sharedInstance] trackTimerResume:@"timerEvent"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), queue, ^{
        [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"timerEvent"];
    });
    [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
        if ([eventName isEqualToString:@"timerEvent"]) {
            XCTAssertEqualWithAccuracy([properties[@"event_duration"] floatValue], 2.5, 0.1);
        }
        [expectation fulfill];
        return NO;
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

//测试动态开启 SensorsAnalyticsEventTypeAppEnd，event_duration 是否从启动开始计算
- (void)testCheckAppEndEventDuration {
    XCTestExpectation *expect = [self expectationWithDescription:@"异步超时timeout!"];
    
    double durationSecond = 1.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(durationSecond * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[SensorsAnalyticsSDK sharedInstance] enableAutoTrack:SensorsAnalyticsEventTypeAppEnd];
#pragma clang diagnostic pop
        
        [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL(NSString * _Nonnull eventName, NSMutableDictionary<NSString *,id> * _Nonnull properties) {
            
            if ([eventName isEqualToString:@"$AppEnd"]) {
                double duration = [properties[@"event_duration"] doubleValue];
                
                XCTAssertGreaterThan(duration, durationSecond);
                [expect fulfill];
            }
            return YES;
        }];
        [[SensorsAnalyticsSDK sharedInstance] track:@"$AppEnd"];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

- (void)testCrossTrackTimer {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    __block NSString *timer1;
    __block NSString *timer2;
    dispatch_queue_t queue = dispatch_queue_create("sensorsData-Test", DISPATCH_QUEUE_SERIAL);
    timer1 = [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"testTimer"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), queue, ^{
        timer2 = [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"testTimer"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), queue, ^{
        [[SensorsAnalyticsSDK sharedInstance] trackTimerPause:timer1];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), queue, ^{
        [[SensorsAnalyticsSDK sharedInstance] trackTimerPause:timer2];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), queue, ^{
        [[SensorsAnalyticsSDK sharedInstance] trackTimerResume:timer1];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), queue, ^{
        [[SensorsAnalyticsSDK sharedInstance] trackTimerResume:timer2];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)), queue, ^{
        [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:timer1];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(14 * NSEC_PER_SEC)), queue, ^{
        [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:timer2];
    });
 
    [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
        if ([eventName isEqualToString:@"timerEvent"]) {
            XCTAssertEqualWithAccuracy([properties[@"event_duration"] floatValue], 8, 0.1);
        }
        [expectation fulfill];
        return NO;
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

@end
