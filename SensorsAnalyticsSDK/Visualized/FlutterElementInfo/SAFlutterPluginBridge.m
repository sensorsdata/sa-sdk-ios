//
// SAFlutterPluginBridge.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/7/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAFlutterPluginBridge.h"
#import "SAVisualizedObjectSerializerManager.h"
#import "SAVisualizedManager.h"
#import "SAJSONUtil.h"
#import "SAValidator.h"
#import "SALog.h"


/** 可视化全埋点状态改变，包括连接状态和自定义属性配置

    userInfo 传递参数

    可视化全埋点连接状态改变: {context：connectionStatus}

    自定义属性配置更新: {context：propertiesConfig}
 */
static NSNotificationName const kSAVisualizedStatusChangedNotification = @"SensorsAnalyticsVisualizedStatusChangedNotification";

@interface SAFlutterPluginBridge()

@property (nonatomic, copy) NSString *visualPropertiesConfig;

@end

@implementation SAFlutterPluginBridge

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAFlutterPluginBridge *bridge = nil;
    dispatch_once(&onceToken, ^{
        bridge = [[SAFlutterPluginBridge alloc] init];
    });
    return bridge;
}

- (BOOL)isVisualConnectioned {
    return [SAVisualizedManager.defaultManager.visualizedConnection isVisualizedConnecting];
}

// 修改可视化全埋点连接状态
- (void)changeVisualConnectionStatus:(BOOL)isConnectioned {

    [[NSNotificationCenter defaultCenter] postNotificationName:kSAVisualizedStatusChangedNotification object:nil userInfo:@{@"context": @"connectionStatus"}];
}

// 修改自定义属性配置
- (void)changeVisualPropertiesConfig:(NSDictionary *)propertiesConfig {
    if (![SAValidator isValidDictionary:propertiesConfig]) {
        return;
    }

    // 注入完整配置信息
    NSData *callJSData = [SAJSONUtil dataWithJSONObject:propertiesConfig];
    // base64 编码，避免转义字符丢失的问题
    NSString *base64JsonString = [callJSData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    self.visualPropertiesConfig = base64JsonString;

    [[NSNotificationCenter defaultCenter] postNotificationName:kSAVisualizedStatusChangedNotification object:nil userInfo:@{@"context": @"propertiesConfig"}];

}

// 更新 Flutter 页面元素信息
- (void)updateFlutterElementInfo:(NSString *)jsonString {
    if (!jsonString) {
        return;
    }
    NSMutableDictionary *messageDic = [SAJSONUtil JSONObjectWithString:jsonString options:NSJSONReadingMutableContainers];
    if (![messageDic isKindOfClass:[NSDictionary class]]) {
        SALogError(@"Message body is formatted failure from Flutter");
        return;
    }
    [[SAVisualizedObjectSerializerManager sharedInstance] saveVisualizedMessage:messageDic];
}

@end
