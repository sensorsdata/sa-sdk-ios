//
// SANetworkInfoPropertyPluginTests.m
// SensorsAnalyticsTests
//
// Created by yuqiang on 2022/3/31.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "SANetworkInfoPropertyPlugin.h"

@interface SANetworkInfoPropertyPluginTests : XCTestCase

@property (nonatomic, strong) SANetworkInfoPropertyPlugin *plugin;

@end

@implementation SANetworkInfoPropertyPluginTests

- (void)setUp {
    _plugin = [[SANetworkInfoPropertyPlugin alloc] init];
}

- (void)tearDown {
    _plugin = nil;
}

- (void)testCurrentNetworkTypeOptions {
    // 单元测试获取不到网络信息
//    XCTAssertTrue(self.plugin.currentNetworkTypeOptions == SensorsAnalyticsNetworkTypeNONE);
}

- (void)testNetworkType {
    // 单元测试获取不到网络信息
//    XCTAssertNotNil(self.plugin.properties[@"$network_type"]);
}

- (void)testWifi {
    // 单元测试获取不到网络信息
//    XCTAssertFalse(self.plugin.properties[@"$wifi"]);
}


@end
