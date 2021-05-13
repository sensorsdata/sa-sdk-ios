//
// SALinkHandlerTests.m
// SensorsAnalyticsTests
//
// Created by 彭远洋 on 2020/1/16.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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
#import "SADeeplinkManager.h"
#import "SAConfigOptions.h"
#import "SAFileStore.h"

@interface SALinkHandlerTests : XCTestCase

@property (nonatomic, strong) SADeeplinkManager *linkHandler;

@end

@implementation SALinkHandlerTests

- (void)setUp {
    NSString *urlString = @"https://www.sensorsdata.cn?utm_content=1&utm_campaign=1&utm_medium=1&utm_source=1&utm_term=1&channel=1&source=1&key=value";
    NSURL *url = [NSURL URLWithString:urlString];
    NSDictionary *launchOptions = @{UIApplicationLaunchOptionsURLKey: url};
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:launchOptions];
    options.enableSaveDeepLinkInfo = YES;
    options.sourceChannels = @[@"source", @"channel", @"device_id"];
    _linkHandler = [[SADeeplinkManager alloc] init];
    _linkHandler.configOptions = options;
}

- (void)tearDown {

}

#pragma mark - positive case
- (void)testURLValidity {
    NSURL *invalid1 = [NSURL URLWithString:@"https://www.sensorsdata.cn"];
    XCTAssertFalse([_linkHandler canHandleURL:invalid1]);

    NSURL *invalid2 = [NSURL URLWithString:@"https://www.sensorsdata.cn?utm_test=test&key=value"];
    XCTAssertFalse([_linkHandler canHandleURL:invalid2]);

    NSURL *valid1 = [NSURL URLWithString:@"https://www.sensorsdata.cn?source=source"];
    XCTAssertTrue([_linkHandler canHandleURL:valid1]);

    NSURL *valid2 = [NSURL URLWithString:@"https://www.sensorsdata.cn?utm_content=content"];
    XCTAssertTrue([_linkHandler canHandleURL:valid2]);
}

- (void)testLaunchOptions {
    NSDictionary *latest = [_linkHandler latestUtmProperties];
    XCTAssertTrue(latest.count == 7);
    XCTAssertTrue([latest[@"$latest_utm_content"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_campaign"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_medium"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_source"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_term"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"_latest_channel"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"_latest_source"] isEqualToString:@"1"]);

    NSDictionary *utm = [_linkHandler utmProperties];
    XCTAssertTrue(utm.count == 7);
    XCTAssertTrue([utm[@"$utm_content"] isEqualToString:@"1"]);
    XCTAssertTrue([utm[@"$utm_campaign"] isEqualToString:@"1"]);
    XCTAssertTrue([utm[@"$utm_medium"] isEqualToString:@"1"]);
    XCTAssertTrue([utm[@"$utm_source"] isEqualToString:@"1"]);
    XCTAssertTrue([utm[@"$utm_term"] isEqualToString:@"1"]);
    XCTAssertTrue([utm[@"channel"] isEqualToString:@"1"]);
    XCTAssertTrue([utm[@"source"] isEqualToString:@"1"]);
}

- (void)testClearUtmProperties {
    [_linkHandler clearUtmProperties];
    NSDictionary *utm = [_linkHandler utmProperties];
    XCTAssertTrue(utm.count == 0);
}

- (void)testNormalURL {
    NSURL *url = [NSURL URLWithString:@"https://www.sensorsdata.cn?utm_content=2&utm_campaign=2&channel=2&key=value"];
    XCTAssertTrue([_linkHandler canHandleURL:url]);
    [_linkHandler handleURL:url];
    NSDictionary *latest = [_linkHandler latestUtmProperties];
    XCTAssertTrue(latest.count == 3);
    XCTAssertTrue([latest[@"$latest_utm_content"] isEqualToString:@"2"]);
    XCTAssertTrue([latest[@"$latest_utm_campaign"] isEqualToString:@"2"]);
    XCTAssertTrue([latest[@"_latest_channel"] isEqualToString:@"2"]);

    NSDictionary *utm = [_linkHandler utmProperties];
    XCTAssertTrue(utm.count == 3);
    XCTAssertTrue([utm[@"$utm_content"] isEqualToString:@"2"]);
    XCTAssertTrue([utm[@"$utm_campaign"] isEqualToString:@"2"]);
    XCTAssertTrue([utm[@"channel"] isEqualToString:@"2"]);
}

- (void)testEmptyContentOfPart {
    NSURL *url = [NSURL URLWithString:@"https://www.sensorsdata.cn?utm_content=&utm_campaign=3&channel=&key=value"];
    XCTAssertTrue([_linkHandler canHandleURL:url]);

    [_linkHandler handleURL:url];
    NSDictionary *latest = [_linkHandler latestUtmProperties];
    XCTAssertTrue(latest.count == 1);
    XCTAssertTrue([latest[@"$latest_utm_campaign"] isEqualToString:@"3"]);

    NSDictionary *utm = [_linkHandler utmProperties];
    XCTAssertTrue(utm.count == 1);
    XCTAssertTrue([utm[@"$utm_campaign"] isEqualToString:@"3"]);
}

- (void)testEmptyContentOfAll {
    NSURL *url = [NSURL URLWithString:@"https://www.sensorsdata.cn?utm_content=&utm_campaign=&channel=&key=value"];
    XCTAssertTrue([_linkHandler canHandleURL:url]);

    [_linkHandler handleURL:url];
    NSDictionary *latest = [_linkHandler latestUtmProperties];
    XCTAssertTrue(latest.count == 0);

    NSDictionary *utm = [_linkHandler utmProperties];
    XCTAssertTrue(utm.count == 0);
}

- (void)testNoQueryURL {
    NSURL *url = [NSURL URLWithString:@"https://www.sensorsdata.cn"];
    XCTAssertFalse([_linkHandler canHandleURL:url]);

    [_linkHandler handleURL:url];

    NSDictionary *latest = [_linkHandler latestUtmProperties];
    XCTAssertTrue(latest.count == 7);
    XCTAssertTrue([latest[@"$latest_utm_content"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_campaign"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_medium"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_source"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_term"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"_latest_channel"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"_latest_source"] isEqualToString:@"1"]);

    NSDictionary *utm = [_linkHandler utmProperties];
    XCTAssertTrue(utm.count == 0);
}

- (void)testNormalAppStart {
    // 重新初始化 handler 模拟自然启动
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:nil];
    options.enableSaveDeepLinkInfo = YES;
    options.sourceChannels = @[@"source", @"channel"];
    _linkHandler = [[SADeeplinkManager alloc] init];
    _linkHandler.configOptions = options;

    NSDictionary *latest = [_linkHandler latestUtmProperties];
    XCTAssertTrue(latest.count == 7);
    XCTAssertTrue([latest[@"$latest_utm_content"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_campaign"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_medium"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_source"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_term"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"_latest_source"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"_latest_channel"] isEqualToString:@"1"]);

    NSDictionary *utm = [_linkHandler utmProperties];
    XCTAssertTrue(utm.count == 0);
}

- (void)testVersionUpdate {
    // 重新初始化 handler 模拟自然启动
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:nil];
    options.enableSaveDeepLinkInfo = YES;
    //升级版本修改 sourceChannels 后，会过滤本地获取到的自定义属性
    options.sourceChannels = @[@"version", @"channel"];
    _linkHandler = [[SADeeplinkManager alloc] init];
    _linkHandler.configOptions = options;

    NSDictionary *latest = [_linkHandler latestUtmProperties];
    XCTAssertTrue(latest.count == 6);
    XCTAssertTrue([latest[@"$latest_utm_content"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_campaign"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_medium"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_source"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_term"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"_latest_channel"] isEqualToString:@"1"]);

    NSDictionary *utm = [_linkHandler utmProperties];
    XCTAssertTrue(utm.count == 0);
}

#pragma mark - reverse case
- (void)testFilterReservedProperty {
    NSURL *url = [NSURL URLWithString:@"https://www.sensorsdata.cn?utm_content=2&device_id=2"];
    XCTAssertTrue([_linkHandler canHandleURL:url]);

    [_linkHandler handleURL:url];
    NSDictionary *latest = [_linkHandler latestUtmProperties];
    XCTAssertTrue(latest.count == 1);
    XCTAssertTrue([latest[@"$latest_utm_content"] isEqualToString:@"2"]);

    NSDictionary *utm = [_linkHandler utmProperties];
    XCTAssertTrue(utm.count == 1);
    XCTAssertTrue([utm[@"$utm_content"] isEqualToString:@"2"]);
}

- (void)testChangeSoureChannels {
    // 重新初始化 handler 模拟自然启动
    // 重新赋值 sourceChannels。当本地保存的自定义数据不在新的 sourceChannels 列表中时直接过滤掉
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:nil];
    options.enableSaveDeepLinkInfo = YES;
    options.sourceChannels = @[@"sourceChannel"];
    _linkHandler = [[SADeeplinkManager alloc] init];
    _linkHandler.configOptions = options;

    NSDictionary *latest = [_linkHandler latestUtmProperties];
    XCTAssertTrue(latest.count == 5);
    XCTAssertTrue([latest[@"$latest_utm_content"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_campaign"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_medium"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_source"] isEqualToString:@"1"]);
    XCTAssertTrue([latest[@"$latest_utm_term"] isEqualToString:@"1"]);

    NSDictionary *utm = [_linkHandler utmProperties];
    XCTAssertTrue(utm.count == 0);
}

@end
