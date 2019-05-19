//
//  SensorsAnalyticsTests.m
//  SensorsAnalyticsTests
//
//  Created by 张敏超 on 2019/3/12.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <XCTest/XCTest.h>
#import "SAConfigOptions.h"
#import "SensorsAnalyticsSDK.h"
#import "MessageQueueBySqlite.h"

@interface SensorsAnalyticsTests : XCTestCase
@property (nonatomic, weak) SensorsAnalyticsSDK *sensorsAnalytics;
@end

@interface SensorsAnalyticsSDK()
@property (atomic, strong) MessageQueueBySqlite *messageQueue;
@end

@implementation SensorsAnalyticsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.sensorsAnalytics = [SensorsAnalyticsSDK sharedInstance];
    if (!self.sensorsAnalytics) {
        SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:nil];
        [SensorsAnalyticsSDK sharedInstanceWithConfig:options];
        self.sensorsAnalytics = [SensorsAnalyticsSDK sharedInstance];
    }
}

- (void)tearDown {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat"
    [self.sensorsAnalytics trackEventCallback:nil];
#pragma clang diagnostic pop
    self.sensorsAnalytics = nil;
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

#pragma mark - fix bug
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
- (void)testItemSet {
    NSInteger lastCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
    [[SensorsAnalyticsSDK sharedInstance] itemSetWithType:@"itemSet0517" itemId:@"itemId0517" properties:@{@"itemSet":@"acsdfgvzscd"}];
    
    sleep(1);
    
    NSInteger newCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
    BOOL insertSucceed = lastCount == newCount - 1;
    XCTAssertTrue(insertSucceed);
}

- (void)testItemDelete {
    NSInteger lastCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
    [[SensorsAnalyticsSDK sharedInstance] itemDeleteWithType:@"itemSet0517" itemId:@"itemId0517"];
    
    sleep(1);
    
    NSInteger newCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
    BOOL insertSucceed = lastCount == newCount - 1;
    XCTAssertTrue(insertSucceed);
}
@end
