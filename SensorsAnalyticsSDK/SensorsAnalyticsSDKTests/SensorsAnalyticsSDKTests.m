//
//  SensorsAnalyticsSDKTests.m
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/6.
//  Copyright (c) 2015年 SensorsData. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsException.h"
#import "SALogger.h"


@interface SensorsAnalyticsSDKTests : XCTestCase


@end

@implementation SensorsAnalyticsSDKTests {
    NSMutableArray *_filePathList;
}

- (void)setUp {
    [super setUp];
    NSArray * fileNameList = @[@"sensorsanalytics-message.plist", @"sensorsanalytics-distinct_id.plist", @"sensorsanalytics-super_properties.plist"];
    _filePathList = [NSMutableArray array];
    for (NSString *filename in fileNameList) {
        NSString *filepath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
                              stringByAppendingPathComponent:filename];
        [_filePathList addObject:filepath];
    }


}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit{
    // 删除sqlite、distinctId、superProperties对应的数据库文件
    for (NSString * filepath in _filePathList) {
        NSFileManager * fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:filepath]) {
            SADebug(@"remove file:%@", filepath);
            [fm removeItemAtPath:filepath error:NULL];
        }
    }
    // 初始化
    NSString *_serverURL = @"http://test03:8100/sa";
    SensorsAnalyticsSDK * sdk = [SensorsAnalyticsSDK sharedInstance];
    XCTAssertNil(sdk);
    sdk = [SensorsAnalyticsSDK sharedInstanceWithServerURL:_serverURL andFlushInterval:50];
    XCTAssertNotNil(sdk);
    XCTAssertEqual(_serverURL, sdk.serverURL);
    XCTAssertEqual(50, sdk.flushInterval);
    sdk = [SensorsAnalyticsSDK sharedInstanceWithServerURL:_serverURL andFlushInterval:10000000];
    XCTAssertNotNil(sdk);
    XCTAssertEqual(_serverURL, sdk.serverURL);
    // 注意，由于是一个单例，所以第二次初始化传进去的值其实是没有变化的
    XCTAssertEqual(50, sdk.flushInterval);
    SensorsAnalyticsSDK * anotherSDK = [SensorsAnalyticsSDK sharedInstance];
    XCTAssertEqual(sdk, anotherSDK);
    XCTAssertEqual(sdk.libVersion, @"1.2.0");
}

- (void)testTrack {
    SensorsAnalyticsSDK * sdk = [SensorsAnalyticsSDK sharedInstance];
    XCTAssertNotNil(sdk);
    [NSThread sleepForTimeInterval:1];
    // 有一个默认的@appStart事件
    XCTAssertEqual(1, [sdk currentQueueCount]);
    // 1. 加入正确的，看看Queue是否正确增长
    // 1.1 无参数的track
    for (int i =0; i<9; i++) {
        [sdk track:@"Login1"];
    }
    // 这里要sleep，是为了等待异步执行完成才能比较，下同
    [NSThread sleepForTimeInterval:2];
    XCTAssertEqual(10, [sdk currentQueueCount]);
    // 1.2 有参数的track
    for (int i = 0; i < 5; i++) {
        [sdk track:@"Search_2" withProperties:@{@"query": @"baidu", @"BOOL" : @YES, @"Date": [NSDate date]}];
    }
    [NSThread sleepForTimeInterval:2];
    XCTAssertEqual(15, [sdk currentQueueCount]);
    // 1.3 identify
    [sdk identify:@"my id"];
    [NSThread sleepForTimeInterval:1];
    XCTAssertEqual(sdk.distinctId, @"my id");
    // 与文件中的内容对比一下
    NSString * distinct_id = [NSKeyedUnarchiver unarchiveObjectWithFile:_filePathList[1]];
    XCTAssert([distinct_id isEqualToString:@"my id"]);
    // 1.4 profile相关的操作
    [sdk.people set: @{@"gender": @"unknown"}];
    [sdk.people set:@"gender" to:@"female"];
    [sdk.people set:@"age" to:@18];
    [sdk.people append:@"array" by:[NSSet setWithObjects:@"123", @"124", nil]];
    [sdk.people unset:@"array"];
    [sdk.people increment:@"age" by:@12];
    [sdk.people increment:@{@"age":@1}];
    [sdk.people deleteUser];
    [NSThread sleepForTimeInterval:2];
    XCTAssertEqual(23, [sdk currentQueueCount]);
    // 1.5 superProperty的操作
    // 第一次register
    [sdk registerSuperProperties:@{@"number":@1, @"string":@"1"}];
    [NSThread sleepForTimeInterval:1];
    XCTAssertEqual([[sdk currentSuperProperties] count], 2);
    XCTAssert([[sdk currentSuperProperties][@"number"] isEqualToNumber: @1]);
    XCTAssert([[sdk currentSuperProperties][@"string"] isEqualToString:@"1"]);
    XCTAssertNil([sdk currentSuperProperties][@"newstring"]);
    // 第二次register，测试一下merger
    [sdk registerSuperProperties:@{@"number":@2, @"newstring":@"2"}];
    [NSThread sleepForTimeInterval:1];
    XCTAssertEqual([[sdk currentSuperProperties] count], 3);
    XCTAssert([[sdk currentSuperProperties][@"number"] isEqualToNumber:@2]);
    XCTAssert([[sdk currentSuperProperties][@"string"] isEqualToString:@"1"]);
    XCTAssert([[sdk currentSuperProperties][@"newstring"] isEqualToString:@"2"]);
    // 与文件中的内容对比一下
    NSDictionary * superProperties = [NSKeyedUnarchiver unarchiveObjectWithFile:_filePathList[2]];
    XCTAssertEqual([superProperties count], 3);
    XCTAssert([superProperties[@"number"] isEqualToNumber: @2]);
    XCTAssert([superProperties[@"string"] isEqualToString:@"1"]);
    XCTAssert([superProperties[@"newstring"] isEqualToString: @"2"]);
    // 测试一下unregister
    [sdk unregisterSuperProperty:@"number"];
    [NSThread sleepForTimeInterval:1];
    XCTAssertEqual([[sdk currentSuperProperties] count], 2);
    XCTAssertNil([sdk currentSuperProperties][@"number"]);
    XCTAssert([[sdk currentSuperProperties][@"string"] isEqualToString:@"1"]);
    XCTAssert([[sdk currentSuperProperties][@"newstring"] isEqualToString: @"2"]);
    // 测试一下clear
    [sdk clearSuperProperties];
    [NSThread sleepForTimeInterval:1];
    XCTAssertEqual([[sdk currentSuperProperties] count], 0);
    // 与文件中的内容对比一下
    superProperties = [NSKeyedUnarchiver unarchiveObjectWithFile:_filePathList[2]];
    XCTAssertEqual([superProperties count], 0);
    // 2. 对一些异常类型的处理
    // 2.1 不支持dict的value里面有NSArray
    // track接口
    XCTAssertThrowsSpecific([sdk track:@"event" withProperties:@{@"array": @[@1]}], SensorsAnalyticsException, @"InvalidDataException");
    // register接口
    XCTAssertThrowsSpecific([sdk registerSuperProperties:@{@"array": @[@1]}], SensorsAnalyticsException, @"InvalidDataException");
    // 2.2 不支持dict的key不是NSString
    XCTAssertThrowsSpecific([sdk track:@"event" withProperties:@{@1:@1}], SensorsAnalyticsException, @"InvalidDataException");
    // 2.3 不支持append的内容是非NSString
    NSSet * badSet = [NSSet setWithObjects:@123, nil];
    XCTAssertThrowsSpecific([sdk.people append:@"array" by:badSet], SensorsAnalyticsException, @"InvalidDataException");
    // 2.4 不支持increment的key是非NSString或者内容不是NSNumber
    XCTAssertThrowsSpecific([sdk.people increment:@{@123:@123}], SensorsAnalyticsException, @"InvalidDataException");
    XCTAssertThrowsSpecific([sdk.people increment:@{@"123":@"123"}], SensorsAnalyticsException, @"InvalidDataException");
    // 2.5 event名称含有非法字符
    XCTAssertThrowsSpecific([sdk track:@"search a query"], SensorsAnalyticsException, @"InvalidDataException");
    // 2.6 property名称含有非法字符
    XCTAssertThrowsSpecific([sdk track:@"Search_a_query" withProperties:@{@"query name": @"baidu"}], SensorsAnalyticsException, @"InvalidDataException");
    // 2.7 event名称是保留字
    XCTAssertThrowsSpecific([sdk track:@"event"], SensorsAnalyticsException, @"InvalidDataException");
    // 2.8 property名称是保留字
    XCTAssertThrowsSpecific([sdk track:@"Search_a_query" withProperties:@{@"user_id": @"baidu"}], SensorsAnalyticsException, @"InvalidDataException");

    // 3. 测试一下flush
    // 3.1 signUp会立刻触发
    [sdk signUp:@"new id"];
    [NSThread sleepForTimeInterval:5];
    XCTAssertEqual(sdk.distinctId, @"new id");
    XCTAssertEqual(0, [sdk currentQueueCount]);
    // 与文件中的内容对比一下
    distinct_id = [NSKeyedUnarchiver unarchiveObjectWithFile:_filePathList[1]];
    XCTAssert([distinct_id isEqualToString:@"new id"]);
    // 3.2 signUp后再次发一个track试下
    [sdk track:@"event" withProperties:@{@"123": @"123"}];
    [NSThread sleepForTimeInterval:2];
    XCTAssertEqual(sdk.distinctId, @"new id");
    XCTAssertEqual(1, [sdk currentQueueCount]);
    // 3.3 手动触发一下flush
    [sdk flush];
    [NSThread sleepForTimeInterval:5];
    XCTAssertEqual(sdk.distinctId, @"new id");
    XCTAssertEqual(0, [sdk currentQueueCount]);
    // 3.4 测试一下一定时间以后的自动flush
    NSLog(@"test 3.4");
    for (int i =0; i<10; i++) {
        [sdk track:@"login"];
    }
    [NSThread sleepForTimeInterval:2];
    XCTAssertEqual(10, [sdk currentQueueCount]);
    [NSThread sleepForTimeInterval:50];
    [sdk track:@"login"];
    [NSThread sleepForTimeInterval:1];
    XCTAssertEqual(0, [sdk currentQueueCount]);
    // 4. 测试一下最大messageSize的限制
    for (int i =0; i<1100; i++) {
        [sdk track:@"login"];
    }
    [NSThread sleepForTimeInterval:50];
    XCTAssertEqual(1000, [sdk currentQueueCount]);
    [sdk track:@"login"];
    [NSThread sleepForTimeInterval:10];
    XCTAssertEqual(0, [sdk currentQueueCount]);
    
}


@end
