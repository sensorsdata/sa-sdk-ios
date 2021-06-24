//
//  SAVisualizedConnection.m,
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/4.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SAVisualizedConnection.h"
#import "SAVisualizedMessage.h"
#import "SAVisualizedSnapshotMessage.h"
#import "SALog.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAVisualizedObjectSerializerManager.h"
#import "SAConstants+Private.h"
#import "SAVisualizedManager.h"
#import "SAVisualizedLogger.h"

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

    [notificationCenter addObserver:self selector:@selector(receiveVisualizedMessageFromH5:) name:SA_VISUALIZED_H5_MESSAGE_NOTIFICATION object:nil];
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

- (void)receiveVisualizedMessageFromH5:(NSNotification *)notification {
    WKScriptMessage *message = notification.object;
    WKWebView *webView = message.webView;
    if (![webView isKindOfClass:WKWebView.class]) {
        SALogError(@"Message webview is invalid from JS SDK");
        return;
    }

    NSData *messageData = [message.body dataUsingEncoding:NSUTF8StringEncoding];
    if (!messageData) {
        SALogError(@"Message body is invalid from JS SDK");
        return;
    }

    NSDictionary *messageDic = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];
    if (![messageDic isKindOfClass:[NSDictionary class]]) {
        SALogError(@"Message body is formatted failure from JS SDK");
        return;
    }

    [[SAVisualizedObjectSerializerManager sharedInstance] saveVisualizedWebPageInfoWithWebView:webView webPageInfo: messageDic];
}

/// 开始计时
- (void)startSendMessageTimer {
    _commandQueue.suspended = NO;
    if (self.timer && [self.timer isValid]) {
        // 恢复
        [self.timer setFireDate:[NSDate date]];
        return;
    }
}

/// 暂停计时
- (void)stopSendMessageTimer {
    _commandQueue.suspended = YES;
    if (self.timer) {
        // 暂停计时
        [self.timer setFireDate:[NSDate distantFuture]];
    }
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
    [[SAVisualizedObjectSerializerManager sharedInstance] resetObjectSerializer];
    [[SAVisualizedObjectSerializerManager sharedInstance] cleanVisualizedWebPageInfoCache];

    // 关闭埋点校验
    [SAVisualizedManager.sharedInstance enableEventCheck:NO];

    // 关闭诊断信息收集
    [SAVisualizedManager.sharedInstance.visualPropertiesTracker enableCollectDebugLog:NO];
}

- (BOOL)isVisualizedConnecting {
    return _timer && _timer.valid;
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
                NSData *jsonData = [urlResponseContent dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
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
        SALogWarn(@"Not sending message as we are not connected: %@", [message debugDescription]);
    }
}

/// 解析调试信息
- (void)analysisDebugMessage:(NSDictionary *)message {
    if (message.count == 0) {
        return;
    }
    
    // 解析可视化全埋点配置
    NSDictionary *configDic = message[@"visualized_sdk_config"];
    // 是否关闭自定义属性
    BOOL disableConfig = [message[@"visualized_config_disabled"] boolValue];
    if (disableConfig) {
        NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"开关控制" message:@"轮询接口返回，运维配置，关闭自定义属性"];
        SALogDebug(@"%@", logMessage);
        
        [SAVisualizedManager.sharedInstance.configSources setupConfigWithDictionary:nil disableConfig:YES];
    } else if (configDic.count > 0) {
        NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"轮询接口更新可视化全埋点配置，%@", configDic];
        SALogInfo(@"%@", logMessage);
        
        [SAVisualizedManager.sharedInstance.configSources setupConfigWithDictionary:configDic disableConfig:NO];
    }
    
    // 前端页面进入 &debug=1 调试模式
    BOOL isDebug = [message[@"visualized_debug_mode_enabled"] boolValue];
    [SAVisualizedManager.sharedInstance.visualPropertiesTracker enableCollectDebugLog:isDebug];
}


- (id <SAVisualizedMessage>)designerMessageForMessage:(id)message {
    if (![message isKindOfClass:[NSString class]] && ![message isKindOfClass:[NSData class]]) {
        SALogError(@"message type error:%@",message);
        return nil;
    }

    NSData *jsonData = [message isKindOfClass:[NSString class]] ? [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding] : message;
    NSError *error = nil;
    id jsonObject = nil;

    @try {
        jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    } @catch (NSException *exception) {
        SALogError(@"Badly formed socket message error: %@", exception);
    }

    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        SALogError(@"Badly formed socket message expected JSON dictionary: %@", error);
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

- (void)startVisualizedTimer:(id)message featureCode:(NSString *)featureCode postURL:(NSString *)postURL {
    _featureCode = featureCode;
    _postUrl = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)postURL, CFSTR(""),  CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
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
    NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];

    NSString *jsonPath = [sensorsBundle pathForResource:@"sa_visualized_path.json" ofType:nil];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    _commandQueue.suspended = NO;
    self->_connected = YES;
    [self startVisualizedTimer:jsonString featureCode:featureCode postURL:urlStr];
}

@end

