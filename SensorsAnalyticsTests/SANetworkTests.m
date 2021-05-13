//
//  SANetworkTests.m
//  SANetworkTests
//
//  Created by 张敏超 on 2019/3/12.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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
#import "SASecurityPolicy.h"
#import "SANetwork.h"
#import "SAURLUtils.h"


@interface SANetworkTests : XCTestCase
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) SANetwork *network;
@end

@implementation SANetworkTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _url = [NSURL URLWithString:@"https://sdk-test.datasink.sensorsdata.cn/sa?project=zhangminchao&token=95c73ae661f85aa0"];
    _network = [[SANetwork alloc] init];
}

- (void)tearDown {
    _url = nil;
    _network = nil;
}

#pragma mark - Fix Bug
/**
 版本：1.11.0（已删除）

 NSURLComponents 的 query 属性获取时，会做解码，导致 H5 数据打通失败
 */
- (void)testFixGetQueryItemsWithURLIsEncoded {
    NSString *event = @"event";
    NSString *eventValue = @"%7B%22server_url%22%3A%22http%3A%2F%2Fsdk-test.cloud.sensorsdata.cn%3A8006%2Fsa.gif%3Fproject%3Ddefault%26token%3D95c73ae661f85aa0%22%2C%22distinct_id%22%3A%2216a9a6af66b61-048f6185f2a9e5-34753c59-370944-16a9a6af66d0%22%2C%22lib%22%3A%7B%22%24lib%22%3A%22js%22%2C%22%24lib_method%22%3A%22code%22%2C%22%24lib_version%22%3A%221.9.7%22%7D%2C%22properties%22%3A%7B%22%24screen_height%22%3A896%2C%22%24screen_width%22%3A414%2C%22%24lib%22%3A%22js%22%2C%22%24lib_version%22%3A%221.9.7%22%2C%22%24referrer%22%3A%22%22%2C%22%24referrer_host%22%3A%22%22%2C%22%24url%22%3A%22file%3A%2F%2F%2FUsers%2Fminchao%2FLibrary%2FDeveloper%2FCoreSimulator%2FDevices%2FF412A5FF-7F06-4DDC-968C-D0A15F7FC91D%2Fdata%2FContainers%2FBundle%2FApplication%2F3F4101C3-48C2-4D6F-A4B9-FD2FB1B827C7%2FHelloSensorsAnalytics.app%2Ftest2.html%22%2C%22%24url_path%22%3A%22%2FUsers%2Fminchao%2FLibrary%2FDeveloper%2FCoreSimulator%2FDevices%2FF412A5FF-7F06-4DDC-968C-D0A15F7FC91D%2Fdata%2FContainers%2FBundle%2FApplication%2F3F4101C3-48C2-4D6F-A4B9-FD2FB1B827C7%2FHelloSensorsAnalytics.app%2Ftest2.html%22%2C%22%24title%22%3A%22Title%22%2C%22%24latest_referrer%22%3A%22%E5%8F%96%E5%80%BC%E5%BC%82%E5%B8%B8%22%2C%22%24latest_referrer_host%22%3A%22%E5%8F%96%E5%80%BC%E5%BC%82%E5%B8%B8%22%2C%22%24latest_search_keyword%22%3A%22%E5%8F%96%E5%80%BC%E5%BC%82%E5%B8%B8%22%2C%22%24latest_traffic_source_type%22%3A%22%E5%8F%96%E5%80%BC%E5%BC%82%E5%B8%B8%22%2C%22%24is_first_day%22%3Afalse%2C%22%24is_first_time%22%3Afalse%7D%2C%22type%22%3A%22track%22%2C%22event%22%3A%22%24pageview%22%2C%22_nocache%22%3A%22047035893734089%22%7D";
    NSString *urlString = [NSString stringWithFormat:@"sensorsanalytics://trackEvent?%@=%@", event, eventValue];
    NSDictionary *items = [SAURLUtils queryItemsWithURLString:urlString];
    BOOL isEqual = [items isEqualToDictionary:@{event: eventValue}];
    XCTAssertTrue(isEqual);
}

/**
 版本：1.11.0（已删除）

 该版本中当获取 project 为空时，返回了 nil，会影响打通时新的 UserAgent 拼接问题
 v1.11.8 修复该问题，默认 project 返回 default
*/
- (void)testFixNullProjectWithH5UserAgentError {
    NSURL *url = [NSURL URLWithString:@"https://sdk-test.datasink.sensorsdata.cn/sa?token=95c73ae661f85aa0"];
    SANetwork *network = [[SANetwork alloc] init];
    NSString *appendingAgent = [NSString stringWithFormat: @" /sa-sdk-ios/sensors-verify/%@?%@ ", network.host, network.project];
    NSString *agentExpectation = [NSString stringWithFormat: @" /sa-sdk-ios/sensors-verify/%@?default ", network.host];
    XCTAssertTrue([appendingAgent isEqualToString:agentExpectation]);
}

#pragma mark - URL Method
- (void)testGetHostWithURL {
    NSString *host = [SAURLUtils hostWithURL:_url];
    XCTAssertEqualObjects(host, @"sdk-test.datasink.sensorsdata.cn");
}

- (void)testGetHostWithNilURL {
    NSString *host = [SAURLUtils hostWithURL:nil];
    XCTAssertNil(host);
}

- (void)testGetHostWithURLString {
    NSString *host = [SAURLUtils hostWithURLString:@"https://www.google.com"];
    XCTAssertEqualObjects(host, @"www.google.com");
}

- (void)testGetHostWithMalformedURLString {
    NSString *host = [SAURLUtils hostWithURLString:@"google.com"];
    XCTAssertNil(host);
}

- (void)testGetQueryItemsWithURL {
    NSDictionary *items = [SAURLUtils queryItemsWithURL:_url];
    BOOL isEqual = [items isEqualToDictionary:@{@"project": @"zhangminchao", @"token": @"95c73ae661f85aa0"}];
    XCTAssertTrue(isEqual);
}

- (void)testGetQueryItemsWithNilURL {
    NSDictionary *items = [SAURLUtils queryItemsWithURL:nil];
    XCTAssertNil(items);
}

- (void)testGetQueryItemsWithURLString {
    NSDictionary *items = [SAURLUtils queryItemsWithURLString:@"https://sdk-test.datasink.sensorsdata.cn/sa?project=zhangminchao&token=95c73ae661f85aa0"];
    BOOL isEqual = [items isEqualToDictionary:@{@"project": @"zhangminchao", @"token": @"95c73ae661f85aa0"}];
    XCTAssertTrue(isEqual);
}

- (void)testGetQueryItemsWithNilURLString {
    NSDictionary *items = [SAURLUtils queryItemsWithURLString:nil];
    XCTAssertNil(items);
}

#pragma mark - Server URL
- (void)testDebugOffServerURL {
    XCTAssertEqual(self.network.serverURL, self.url);
}

- (void)testDebugOnlyServerURL {
    self.network.debugMode = SensorsAnalyticsDebugOnly;
    XCTAssertTrue([self.network.serverURL.lastPathComponent isEqualToString:@"debug"]);
}

- (void)testDebugAndTrackServerURL {
    self.network.debugMode = SensorsAnalyticsDebugAndTrack;
    XCTAssertTrue([self.network.serverURL.lastPathComponent isEqualToString:@"debug"]);
}

- (void)testGetServerURLHost {
    XCTAssertTrue([self.network.host isEqualToString:@"sdk-test.datasink.sensorsdata.cn"]);
}

- (void)testGetServerURLDefaultHost {
    NSURL *url = [NSURL URLWithString:@""];
    SANetwork *network = [[SANetwork alloc] init];
    XCTAssertTrue([network.host isEqualToString:@""]);
}

- (void)testGetServerURLProject {
    XCTAssertTrue([self.network.project isEqualToString:@"zhangminchao"]);
}

- (void)testGetServerURLDefaultProject {
    NSURL *url = [NSURL URLWithString:@"https://sdk-test.datasink.sensorsdata.cn/sa?token=95c73ae661f85aa0"];
    SANetwork *network = [[SANetwork alloc] init];
    XCTAssertTrue([network.project isEqualToString:@"default"]);
}

- (void)testGetServerURLToken {
    XCTAssertTrue([self.network.token isEqualToString:@"95c73ae661f85aa0"]);
}

- (void)testGetServerURLDefaultToken {
    NSURL *url = [NSURL URLWithString:@"https://sdk-test.datasink.sensorsdata.cn/sa"];
    SANetwork *network = [[SANetwork alloc] init];
    XCTAssertTrue([network.token isEqualToString:@""]);
}

#pragma mark - Certificate
// 测试项目中有两个证书。ca.der.cer DER 格式的证书；ca.cer1 为 CER 格式的过期原始证书，若修改后缀为 cer，会崩溃；ca.outdate.cer 为过期证书
- (void)testCustomCertificate {
    NSURL *url = [NSURL URLWithString:@"https://test.kbyte.cn:4106/sa"];
    SANetwork *network = [[SANetwork alloc] init];
    
    SASecurityPolicy *securityPolicy = [SASecurityPolicy policyWithPinningMode:SASSLPinningModeCertificate];
    securityPolicy.allowInvalidCertificates = YES;
    securityPolicy.validatesDomainName = NO;

//    network.securityPolicy = securityPolicy;
    
//    BOOL success = [network flushEvents:@[@"{\"distinct_id\":\"1231456789\"}"]];
//    XCTAssertTrue(success, @"Error");
}

- (void)testHTTPSServerURL {
//    BOOL success = [self.network flushEvents:@[@"{\"distinct_id\":\"1231456789\"}"]];
//    XCTAssertTrue(success, @"Error");
}

#pragma mark - Request
- (NSArray<NSString *> *)createEventStringWithTime:(NSInteger)time {
    NSMutableArray *strings = [NSMutableArray arrayWithCapacity:50];
    for (NSInteger i = 0; i < 50; i ++) {
        NSInteger sss = time - (50 - i) * 1000 - arc4random()%1000;
        [strings addObject:[NSString stringWithFormat:@"{\"time\":%ld,\"_track_id\":%@,\"event\":\"$AppStart\",\"_flush_time\":%ld,\"distinct_id\":\"newId\",\"properties\":{\"$os_version\":\"12.1\",\"$device_id\":\"7460058E-2468-47C0-9E07-5C6BBADC1676\",\"AAA\":\"7460058E-2468-47C0-9E07-5C6BBADC1676\",\"$os\":\"iOS\",\"$screen_height\":896,\"$is_first_day\":false,\"$lib\":\"iOS\",\"$model\":\"x86_64\",\"$network_type\":\"WIFI\",\"$screen_width\":414,\"$app_version\":\"1.3\",\"$manufacturer\":\"Apple\",\"$wifi\":true,\"$lib_version\":\"1.10.23\",\"$is_first_time\":false,\"$resume_from_background\":false},\"type\":\"track\",\"lib\":{\"$lib_version\":\"1.10.23\",\"$lib\":\"iOS\",\"$lib_method\":\"autoTrack\",\"$app_version\":\"1.3\"}}", sss, @(arc4random()),sss]];
    }
    return strings;
}

- (void)testFlushEvents {
//    XCTestExpectation *expect = [self expectationWithDescription:@"请求超时timeout!"];
//    expect.expectedFulfillmentCount = 2;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//        BOOL success1 = [self.network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000]];
//        BOOL success2 = [self.network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000 - 70000]];
//        XCTAssertTrue(success1 && success2, @"Error");
//
//        [expect fulfill];
//    });
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//        BOOL success1 = [self.network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000 - 70000]];
//        BOOL success2 = [self.network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000]];
//        XCTAssertTrue(success1 && success2, @"Error");
//
//        [expect fulfill];
//    });
//
//    [self waitForExpectationsWithTimeout:45 handler:^(NSError *error) {
//        XCTAssertNil(error);
//    }];
}

- (void)testDebugModeCallback {
//    XCTestExpectation *expect = [self expectationWithDescription:@"请求超时timeout!"];
//
//    NSURLSessionTask *task = [self.network debugModeCallbackWithDistinctId:@"1234567890qwe" params:@{@"key": @"value"}];
//    NSURL *url = task.currentRequest.URL;
    // 验证 url 中必须带有之前的参数，v1.11.0~v1.11.8 版本中有问题，参数拼接有问题
    // 影响范围为 Debug Mode 的回调，不影响正常功能使用
//    XCTAssertTrue([url.absoluteString rangeOfString:@"project=zhangminchao&token=95c73ae661f85aa0"].location != NSNotFound);
//    XCTAssertTrue([url.absoluteString rangeOfString:@"key=value"].location != NSNotFound);
//    XCTAssertTrue([url.absoluteString rangeOfString:self.network.serverURL.host].location != NSNotFound);
    
    // 请求超时时间为 30s
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        if (task.state == NSURLSessionTaskStateRunning) {
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                XCTAssertNil(task.error);
//                [expect fulfill];
//            });
//            return;
//        }
//        XCTAssertNil(task.error);
//        [expect fulfill];
//    });
//    
//    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
//        XCTAssertNil(error);
//    }];
}

- (void)testFunctionalManagermentConfig {
    NSString *remoteConfigVersion = @"1.2.qqq0";
    NSString *eventConfigVersion = @"1.3.qqq0";
    
    XCTestExpectation *expect = [self expectationWithDescription:@"请求超时timeout!"];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
