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

#import "SAScriptMessageHandler.h"
#import "SALog.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAVisualizedObjectSerializerManger.h"


@interface SAScriptMessageHandler ()

@end

@implementation SAScriptMessageHandler

#pragma mark - Life Cycle

+ (instancetype)sharedInstance {
    static SAScriptMessageHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SAScriptMessageHandler alloc] init];
    });
    return sharedInstance;
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

        NSDictionary *messageDic = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];
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

            NSData *trackMessageData = [NSJSONSerialization dataWithJSONObject:trackMessageDic options:0 error:nil];
            NSString *trackMessageString = [[NSString alloc] initWithData:trackMessageData encoding:NSUTF8StringEncoding];
            [[SensorsAnalyticsSDK sharedInstance] trackFromH5WithEvent:trackMessageString];
        } else if ([callType isEqualToString:@"visualized_track"] || [callType isEqualToString:@"app_alert"] || [callType isEqualToString:@"page_info"]) {
            /* 缓存 H5 页面信息
             visualized_track：H5 可点击元素数据，数组；
             app_alert：H5 弹框信息，提示配置错误信息；
             page_info：H5 页面信息，包括 url 和 title
             */
            WKWebView *webView = message.webView;
            [[SAVisualizedObjectSerializerManger sharedInstance] saveVisualizedWebPageInfoWithWebView:webView webPageInfo: messageDic];
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
}

@end
