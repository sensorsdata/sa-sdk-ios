//
// SAScriptMessageHandler.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/3/18.
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

#import "SAJavaScriptBridgeManager.h"
#import "SALog.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAModuleManager.h"
#import "WKWebView+SABridge.h"
#import "SAJSONUtil.h"
#import "SASwizzle.h"

@interface SAJavaScriptBridgeManager ()

@end

@implementation SAJavaScriptBridgeManager

#pragma mark - Life Cycle

+ (instancetype)sharedInstance {
    return (SAJavaScriptBridgeManager *)[SAModuleManager.sharedInstance managerForModuleType:SAModuleTypeJavaScriptBridge];
}

#pragma mark - SAModuleProtocol

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    if (enable) {
        [self swizzleWebViewMethod];
    }
}

#pragma mark - SAJavaScriptBridgeModuleProtocol

- (NSString *)javaScriptSource {
    if (!self.configOptions.enableJavaScriptBridge) {
        return nil;
    }
    if (self.configOptions.serverURL) {
        return [SAJavaScriptBridgeBuilder buildJSBridgeWithServerURL:self.configOptions.serverURL];
    }

    SALogError(@"%@ get network serverURL is failed!", self);
    return nil;
}

#pragma mark - Private

- (void)swizzleWebViewMethod {
    static dispatch_once_t onceTokenWebView;
    dispatch_once(&onceTokenWebView, ^{
        NSError *error = NULL;

        [WKWebView sa_swizzleMethod:@selector(loadRequest:)
                         withMethod:@selector(sensorsdata_loadRequest:)
                              error:&error];

        [WKWebView sa_swizzleMethod:@selector(loadHTMLString:baseURL:)
                         withMethod:@selector(sensorsdata_loadHTMLString:baseURL:)
                              error:&error];

        if (@available(iOS 9.0, *)) {
            [WKWebView sa_swizzleMethod:@selector(loadFileURL:allowingReadAccessToURL:)
                             withMethod:@selector(sensorsdata_loadFileURL:allowingReadAccessToURL:)
                                  error:&error];

            [WKWebView sa_swizzleMethod:@selector(loadData:MIMEType:characterEncodingName:baseURL:)
                             withMethod:@selector(sensorsdata_loadData:MIMEType:characterEncodingName:baseURL:)
                                  error:&error];
        }

        if (error) {
            SALogError(@"Failed to swizzle on WKWebView. Details: %@", error);
            error = NULL;
        }
    });
}

- (void)addScriptMessageHandlerWithWebView:(WKWebView *)webView {
    if ([SAModuleManager.sharedInstance isDisableSDK]) {
        return;
    }

    NSAssert([webView isKindOfClass:[WKWebView class]], @"此注入方案只支持 WKWebView！❌");
    if (![webView isKindOfClass:[WKWebView class]]) {
        return;
    }

    @try {
        WKUserContentController *contentController = webView.configuration.userContentController;
        [contentController removeScriptMessageHandlerForName:SA_SCRIPT_MESSAGE_HANDLER_NAME];
        [contentController addScriptMessageHandler:[SAJavaScriptBridgeManager sharedInstance] name:SA_SCRIPT_MESSAGE_HANDLER_NAME];

        NSString *javaScriptSource = [SAModuleManager.sharedInstance javaScriptSource];
        if (javaScriptSource.length == 0) {
            return;
        }

        NSArray<WKUserScript *> *userScripts = contentController.userScripts;
        __block BOOL isContainJavaScriptBridge = NO;
        [userScripts enumerateObjectsUsingBlock:^(WKUserScript *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj.source containsString:kSAJSBridgeServerURL] || [obj.source containsString:kSAJSBridgeVisualizedMode]) {
                isContainJavaScriptBridge = YES;
                *stop = YES;
            }
        }];

        if (!isContainJavaScriptBridge) {
            // forMainFrameOnly:标识脚本是仅应注入主框架（YES）还是注入所有框架（NO）
            WKUserScript *userScript = [[WKUserScript alloc] initWithSource:[NSString stringWithString:javaScriptSource] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
            [contentController addUserScript:userScript];

            // 通知其他模块，开启打通 H5
            if ([javaScriptSource containsString:kSAJSBridgeServerURL]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SA_H5_BRIDGE_NOTIFICATION object:webView];
            }
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
}

#pragma mark - Delegate

// Invoked when a script message is received from a webpage
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:SA_SCRIPT_MESSAGE_HANDLER_NAME]) {
        return;
    }
    
    if (![message.body isKindOfClass:[NSString class]]) {
        SALogError(@"Message body is not kind of 'NSString' from JS SDK");
        return;
    }
    
    @try {
        NSString *body = message.body;
        NSData *messageData = [body dataUsingEncoding:NSUTF8StringEncoding];
        if (!messageData) {
            SALogError(@"Message body is invalid from JS SDK");
            return;
        }
        
        NSDictionary *messageDic = [SAJSONUtil JSONObjectWithData:messageData];
        if (![messageDic isKindOfClass:[NSDictionary class]]) {
            SALogError(@"Message body is formatted failure from JS SDK");
            return;
        }
        
        NSString *callType = messageDic[@"callType"];
        if ([callType isEqualToString:@"app_h5_track"]) {
            // H5 发送事件
            NSDictionary *trackMessageDic = messageDic[@"data"];
            if (![trackMessageDic isKindOfClass:[NSDictionary class]]) {
                SALogError(@"Data of message body is not kind of 'NSDictionary' from JS SDK");
                return;
            }
            
            NSString *trackMessageString = [SAJSONUtil stringWithJSONObject:trackMessageDic];
            [[SensorsAnalyticsSDK sharedInstance] trackFromH5WithEvent:trackMessageString];
        } else if ([callType isEqualToString:@"visualized_track"] || [callType isEqualToString:@"app_alert"] || [callType isEqualToString:@"page_info"]) {
            /* 缓存 H5 页面信息
             visualized_track：H5 可点击元素数据，数组；
             app_alert：H5 弹框信息，提示配置错误信息；
             page_info：H5 页面信息，包括 url、title 和 lib_version
             */
            [[NSNotificationCenter defaultCenter] postNotificationName:SA_VISUALIZED_H5_MESSAGE_NOTIFICATION object:message];
        } else if ([callType isEqualToString:@"abtest"]) {
            // 通知 SensorsABTest，接收到 H5 的请求数据
            [[NSNotificationCenter defaultCenter] postNotificationName:SA_H5_MESSAGE_NOTIFICATION object:message];
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
}

@end

/// 打通 Bridge
NSString * const kSAJSBridgeObject = @"window.SensorsData_iOS_JS_Bridge = {};";

/// 打通设置 serverURL
NSString * const kSAJSBridgeServerURL = @"window.SensorsData_iOS_JS_Bridge.sensorsdata_app_server_url";

/// 可视化 Bridge
NSString * const kSAVisualBridgeObject = @"window.SensorsData_App_Visual_Bridge = {};";

/// 标识扫码进入可视化模式
NSString * const kSAJSBridgeVisualizedMode = @"window.SensorsData_App_Visual_Bridge.sensorsdata_visualized_mode";

/// 自定义属性 Bridge
NSString * const kSAVisualPropertyBridge = @"window.SensorsData_APP_New_H5_Bridge = {};";

/// 写入自定义属性配置
NSString * const kSAJSBridgeVisualConfig = @"window.SensorsData_APP_New_H5_Bridge.sensorsdata_get_app_visual_config";

/// js 方法调用
NSString * const kSAJSBridgeCallMethod = @"window.sensorsdata_app_call_js";

@implementation SAJavaScriptBridgeBuilder

#pragma mark 注入 js

/// 注入打通bridge，并设置 serverURL
/// @param serverURL 数据接收地址
+ (nullable NSString *)buildJSBridgeWithServerURL:(NSString *)serverURL {
    if (serverURL.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@%@ = '%@';", kSAJSBridgeObject, kSAJSBridgeServerURL, serverURL];
}

/// 注入可视化 bridge，并设置扫码模式
/// @param isVisualizedMode 是否为可视化扫码模式
+ (nullable NSString *)buildVisualBridgeWithVisualizedMode:(BOOL)isVisualizedMode {
    return [NSString stringWithFormat:@"%@%@ = %@;", kSAVisualBridgeObject, kSAJSBridgeVisualizedMode, isVisualizedMode ? @"true" : @"false"];
}

/// 注入自定义属性 bridge，配置信息
/// @param originalConfig 配置信息原始 json
+ (nullable NSString *)buildVisualPropertyBridgeWithVisualConfig:(NSDictionary *)originalConfig {
    if (originalConfig.count == 0) {
        return nil;
    }
    NSMutableString *javaScriptSource = [NSMutableString stringWithString:kSAVisualPropertyBridge];
    [javaScriptSource appendString:kSAJSBridgeVisualConfig];

    // 注入完整配置信息
    NSData *callJSData = [SAJSONUtil dataWithJSONObject:originalConfig];
    // base64 编码，避免转义字符丢失的问题
    NSString *callJSJsonString = [callJSData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    [javaScriptSource appendFormat:@" = '%@';", callJSJsonString];
    return [javaScriptSource copy];
}

#pragma mark JS 方法调用
+ (nullable NSString *)buildCallJSMethodStringWithType:(SAJavaScriptCallJSType)type jsonObject:(nullable id)object {
    NSString *typeString = [self callJSTypeStringWithType:type];
    if (!typeString) {
        return nil;
    }
    NSMutableString *javaScriptSource = [NSMutableString stringWithString:kSAJSBridgeCallMethod];
    if (!object) {
        [javaScriptSource appendFormat:@"('%@')", typeString];
        return [javaScriptSource copy];
    }

    NSData *callJSData = [SAJSONUtil dataWithJSONObject:object];
    if (!callJSData) {
        return nil;
    }
    // base64 编码，避免转义字符丢失的问题
    NSString *callJSJsonString = [callJSData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    [javaScriptSource appendFormat:@"('%@', '%@')", typeString, callJSJsonString];
    return [javaScriptSource copy];
}

+ (nullable NSString *)callJSTypeStringWithType:(SAJavaScriptCallJSType)type {
    switch (type) {
        case SAJavaScriptCallJSTypeVisualized:
            return @"visualized";
        case SAJavaScriptCallJSTypeCheckJSSDK:
            return @"sensorsdata-check-jssdk";
        case SAJavaScriptCallJSTypeUpdateVisualConfig:
            return @"updateH5VisualConfig";
        case SAJavaScriptCallJSTypeWebVisualProperties:
            return @"getJSVisualProperties";
        default:
            return nil;
    }
}

@end
