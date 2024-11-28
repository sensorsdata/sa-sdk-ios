//
// SAVisualizedConnection.m,
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/9/4.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SAVisualizedConnection.h"
#import "SAVisualizedMessage.h"
#import "SAVisualizedSnapshotMessage.h"
#import "SALog.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAVisualizedObjectSerializerManager.h"
#import "SAJSONUtil.h"
#import "SAConstants+Private.h"
#import "SAVisualizedManager.h"
#import "SAVisualizedLogger.h"
#import "SAFlutterPluginBridge.h"
#import "SAVisualizedResources.h"

@interface SAVisualizedConnection ()
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation SAVisualizedConnection {
    BOOL _connected;
    NSDictionary *_typeToMessageClassMap;
    NSOperationQueue *_commandQueue;
    id<SAVisualizedMessage> _designerMessage;
    NSString *_featureCode;
    NSString *_postUrl;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _typeToMessageClassMap = @{
            SAVisualizedSnapshotRequestMessageType : [SAVisualizedSnapshotRequestMessage class],
        };
        _connected = NO;
        _commandQueue = [[NSOperationQueue alloc] init];
        _commandQueue.maxConcurrentOperationCount = 1;
        _commandQueue.suspended = YES;

        [self setUpListeners];
    }

    return self;
}

- (void)setUpListeners {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];

    [notificationCenter addObserver:self selector:@selector(receiveVisualizedMessageFromH5:) name:kSAVisualizedMessageFromH5Notification object:nil];
}

#pragma mark notification Action
- (void)applicationDidBecomeActive {

    // 开启上传信息任务定时器
    [self startSendMessageTimer];
}

- (void)applicationDidEnterBackground {

    // 关闭上传信息任务定时器
    [self stopSendMessageTimer];
}

// App 内嵌 H5 的页面信息，包括页面元素、提示弹框、页面信息
- (void)receiveVisualizedMessageFromH5:(NSNotification *)notification {
    WKScriptMessage *message = notification.object;
    WKWebView *webView = message.webView;
    if (![webView isKindOfClass:WKWebView.class]) {
        SALogError(@"Message webview is invalid from JS SDK");
        return;
    }
    
    NSMutableDictionary *messageDic = [SAJSONUtil JSONObjectWithString:message.body options:NSJSONReadingMutableContainers];
    if (![messageDic isKindOfClass:[NSDictionary class]]) {
        SALogError(@"Message body is formatted failure from JS SDK");
        return;
    }
    
    [[SAVisualizedObjectSerializerManager sharedInstance] saveVisualizedWebPageInfoWithWebView:webView webPageInfo:messageDic];
}


/// 开始计时
- (void)startSendMessageTimer {
    _commandQueue.suspended = NO;
    if (!self.timer || ![self.timer isValid]) {
        return;
    }
    // 恢复计时器
    [self.timer setFireDate:[NSDate date]];

    // 通知外部，开始可视化全埋点连接
    [SAFlutterPluginBridge.sharedInstance changeVisualConnectionStatus:YES];
}

/// 暂停计时
- (void)stopSendMessageTimer {
    _commandQueue.suspended = YES;
    
    if (!self.timer || ![self.timer isValid]) {
        return;
    }

    // 暂停计时
    [self.timer setFireDate:[NSDate distantFuture]];

    // 通知外部，已断开可视化全埋点连接
    [SAFlutterPluginBridge.sharedInstance changeVisualConnectionStatus:NO];
}

#pragma mark action
- (void)close {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }

    if (_commandQueue) {
        [_commandQueue cancelAllOperations];
        _commandQueue = nil;
    }

    // 清空缓存的配置数据
    [[SAVisualizedObjectSerializerManager sharedInstance] cleanVisualizedWebPageInfoCache];

    // 关闭埋点校验
    [SAVisualizedManager.defaultManager enableEventCheck:NO];

    // 关闭诊断信息收集
    [SAVisualizedManager.defaultManager.visualPropertiesTracker enableCollectDebugLog:NO];

    // 通知外部，已断开可视化全埋点连接
    dispatch_async(dispatch_get_main_queue(), ^{
        [SAFlutterPluginBridge.sharedInstance changeVisualConnectionStatus:NO];
    });
}

- (BOOL)isVisualizedConnecting {
    return self.timer && self.timer.isValid;
}

- (void)dealloc {
    [self close];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sendMessage:(id<SAVisualizedMessage>)message {
    if (_connected) {
        if (_featureCode == nil || _postUrl == nil) {
            return;
        }
        NSString *jsonString = [[NSString alloc] initWithData:[message JSONDataWithFeatureCode:_featureCode] encoding:NSUTF8StringEncoding];
        NSURL *URL = [NSURL URLWithString:_postUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
            NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (response.statusCode == 200) {
                NSDictionary *dict = [SAJSONUtil JSONObjectWithString:urlResponseContent];
                int delay = [dict[@"delay"] intValue];
                if (delay < 0) {
                    [self close];
                }
                
                // 切到主线程，和 SAVisualizedManager 中调用一致
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self analysisDebugMessage:dict];
                });
            }
        }];

        [task resume];
    } else {
        SALogWarn(@"No message will be sent because there is no connection: %@", [message debugDescription]);
    }
}

/// 解析调试信息
- (void)analysisDebugMessage:(NSDictionary *)message NS_EXTENSION_UNAVAILABLE("VisualizedAutoTrack not supported for iOS extensions.") {
    // 关闭自定义属性也不再处理调试信息
    if (message.count == 0 || !SAVisualizedManager.defaultManager.configOptions.enableVisualizedProperties) {
        return;
    }

    // 解析可视化全埋点配置
    NSDictionary *configDic = message[@"visualized_sdk_config"];
    // 是否关闭自定义属性
    BOOL disableConfig = [message[@"visualized_config_disabled"] boolValue];
    if (disableConfig) {
        NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"switch control" message:@"the result returned by the polling interface, close custom properties through operations configuration"];
        SALogDebug(@"%@", logMessage);

        [SAVisualizedManager.defaultManager.configSources setupConfigWithDictionary:nil disableConfig:YES];
    } else if (configDic.count > 0) {
        NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"polling interface update visualized configuration, %@", configDic];
        SALogInfo(@"%@", logMessage);

        [SAVisualizedManager.defaultManager.configSources setupConfigWithDictionary:configDic disableConfig:NO];
    }

    // 前端页面进入 &debug=1 调试模式
    BOOL isDebug = [message[@"visualized_debug_mode_enabled"] boolValue];
    [SAVisualizedManager.defaultManager.visualPropertiesTracker enableCollectDebugLog:isDebug];
}


- (id <SAVisualizedMessage>)designerMessageForMessage:(NSString *)message {
    if (![message isKindOfClass:[NSString class]]) {
        SALogError(@"message type error:%@",message);
        return nil;
    }

    id jsonObject = [SAJSONUtil JSONObjectWithString:message];
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        SALogError(@"Badly formed socket message expected JSON dictionary: %@", message);
        return nil;
    }

    NSDictionary *messageDictionary = (NSDictionary *)jsonObject;
    //snapshot_request
    NSString *type = messageDictionary[@"type"];
    NSDictionary *payload = messageDictionary[@"payload"];

    id <SAVisualizedMessage> designerMessage = [_typeToMessageClassMap[type] messageWithType:type payload:payload];
    return designerMessage;
}

#pragma mark -  Methods

- (void)startVisualizedTimer:(NSString *)message featureCode:(NSString *)featureCode postURL:(NSString *)postURL {
    _featureCode = featureCode;
    _postUrl = [postURL stringByRemovingPercentEncoding];
    _designerMessage = [self designerMessageForMessage:message];

    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(handleMessage)
                                                userInfo:nil
                                                 repeats:YES];

    // 发送通知，通知 flutter 已进入可视化全埋点扫码模式
    [SAFlutterPluginBridge.sharedInstance changeVisualConnectionStatus:YES];
}

- (void)handleMessage {
    if (_designerMessage) {
        NSOperation *commandOperation = [_designerMessage responseCommandWithConnection:self];
        if (commandOperation) {
            [_commandQueue addOperation:commandOperation];
        }
    }
}

- (void)startConnectionWithFeatureCode:(NSString *)featureCode url:(NSString *)urlStr {
    NSString *jsonString = [SAVisualizedResources visualizedPath];
    _commandQueue.suspended = NO;
    self->_connected = YES;
    [self startVisualizedTimer:jsonString featureCode:featureCode postURL:urlStr];
}

@end

