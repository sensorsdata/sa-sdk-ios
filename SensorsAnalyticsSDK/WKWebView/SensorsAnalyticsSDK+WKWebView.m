//
// SensorsAnalyticsSDK+WKWebView.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/11/4.
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

#if __has_include("SensorsAnalyticsSDK+WebView.h")
#error This file cannot exist at the same time with `SensorsAnalyticsSDK+WebView.h`. If you usen't `UIWebView`, please delete it.
#endif

#import "SensorsAnalyticsSDK+WKWebView.h"
#import "SAConstants+Private.h"
#import "SACommonUtility.h"
#import "SAJSONUtil.h"
#import "SAURLUtils.h"
#import "SANetwork.h"
#import "SALog.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

static NSString * const kSAJSGetAppInfoScheme = @"sensorsanalytics://getAppInfo";
static NSString * const kSAJSTrackEventNativeScheme = @"sensorsanalytics://trackEvent";

@interface SensorsAnalyticsSDK (WKWebViewPrivate)

@property (atomic, copy) NSString *userAgent;
@property (nonatomic, copy) NSString *addWebViewUserAgent;

@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) dispatch_group_t loadUAGroup;

@property (nonatomic, strong) SANetwork *network;

@end

@implementation SensorsAnalyticsSDK (WKWebView)

#pragma mark - setter/getter
- (void)setWkWebView:(WKWebView *)wkWebView {
    objc_setAssociatedObject(self, @"wkWebView", wkWebView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (WKWebView *)wkWebView {
    return objc_getAssociatedObject(self, @"wkWebView");
}

- (void)setLoadUAGroup:(dispatch_group_t)loadUAGroup {
    objc_setAssociatedObject(self, @"loadUAGroup", loadUAGroup, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_group_t)loadUAGroup {
    return objc_getAssociatedObject(self, @"loadUAGroup");
}

#pragma mark -
- (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion {
    if (self.userAgent) {
        return completion(self.userAgent);
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.wkWebView) {
            dispatch_group_notify(self.loadUAGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                completion(self.userAgent);
            });
        } else {
            self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
            self.loadUAGroup = dispatch_group_create();
            dispatch_group_enter(self.loadUAGroup);

            __weak typeof(self) weakSelf = self;
            [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;

                if (error || !response) {
                    SALogError(@"WKWebView evaluateJavaScript load UA error:%@", error);
                    completion(nil);
                } else {
                    strongSelf.userAgent = response;
                    completion(strongSelf.userAgent);
                }

                // 通过 wkWebView 控制 dispatch_group_leave 的次数
                if (strongSelf.wkWebView) {
                    dispatch_group_leave(strongSelf.loadUAGroup);
                }

                strongSelf.wkWebView = nil;
            }];
        }
    });
}

- (void)addWebViewUserAgentSensorsDataFlag {
    [self addWebViewUserAgentSensorsDataFlag:YES];
}

- (void)addWebViewUserAgentSensorsDataFlag:(BOOL)enableVerify  {
    [self addWebViewUserAgentSensorsDataFlag:enableVerify userAgent:nil];
}

- (void)addWebViewUserAgentSensorsDataFlag:(BOOL)enableVerify userAgent:(nullable NSString *)userAgent {
    __weak typeof(self) weakSelf = self;
    void (^ changeUserAgent)(BOOL verify, NSString *oldUserAgent) = ^void (BOOL verify, NSString *oldUserAgent) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        NSString *newUserAgent = oldUserAgent;
        if ([oldUserAgent rangeOfString:@"sa-sdk-ios"].location == NSNotFound) {
            strongSelf.addWebViewUserAgent = verify ? [NSString stringWithFormat:@" /sa-sdk-ios/sensors-verify/%@?%@ ", strongSelf.network.host, strongSelf.network.project] : @" /sa-sdk-ios";
            newUserAgent = [oldUserAgent stringByAppendingString:strongSelf.addWebViewUserAgent];
        }
        //使 newUserAgent 生效，并设置 newUserAgent
        strongSelf.userAgent = newUserAgent;
        [SACommonUtility saveUserAgent:newUserAgent];
    };

    BOOL verify = enableVerify;
    @try {
        if (![self.network isValidServerURL]) {
            verify = NO;
        }
        NSString *oldAgent = userAgent.length > 0 ? userAgent : self.userAgent;
        if (oldAgent) {
            changeUserAgent(verify, oldAgent);
        } else {
            [self loadUserAgentWithCompletion:^(NSString *ua) {
                changeUserAgent(verify, ua);
            }];
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request {
    return [self showUpWebView:webView WithRequest:request andProperties:nil];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request enableVerify:(BOOL)enableVerify {
    return [self showUpWebView:webView WithRequest:request andProperties:nil enableVerify:enableVerify];
}


- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(NSDictionary *)propertyDict {
    return [self showUpWebView:webView WithRequest:request andProperties:propertyDict enableVerify:NO];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(NSDictionary *)propertyDict enableVerify:(BOOL)enableVerify {
    if (![self shouldHandleWebView:webView request:request]) {
        return NO;
    }
    NSAssert([webView isKindOfClass:WKWebView.class], @"当前集成方式，请使用 WKWebView！❌");

    @try {
        SALogDebug(@"showUpWebView");
        NSDictionary *bridgeCallbackInfo = [self webViewJavascriptBridgeCallbackInfo];
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        if (bridgeCallbackInfo) {
            [properties addEntriesFromDictionary:bridgeCallbackInfo];
        }
        if (propertyDict) {
            [properties addEntriesFromDictionary:propertyDict];
        }
        NSData *jsonData = [SAJSONUtil JSONSerializeObject:properties];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        NSString *js = [NSString stringWithFormat:@"sensorsdata_app_js_bridge_call_js('%@')", jsonString];

        NSString *urlstr = request.URL.absoluteString;
        if (!urlstr) {
            return YES;
        }

        //解析参数
        NSMutableDictionary *paramsDic = [[SAURLUtils queryItemsWithURLString:urlstr] mutableCopy];

        if ([webView isKindOfClass:[WKWebView class]]) {//WKWebView
            SALogDebug(@"showUpWebView: WKWebView");
            if ([urlstr rangeOfString:kSAJSGetAppInfoScheme].location != NSNotFound) {
                [(WKWebView *)webView evaluateJavaScript:js completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                    SALogDebug(@"response: %@ error: %@", response, error);
                }];
            } else if ([urlstr rangeOfString:kSAJSTrackEventNativeScheme].location != NSNotFound) {
                if ([paramsDic count] > 0) {
                    NSString *eventInfo = [paramsDic objectForKey:SA_EVENT_NAME];
                    if (eventInfo != nil) {
                        NSString *encodedString = [eventInfo stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [self trackFromH5WithEvent:encodedString enableVerify:enableVerify];
                    }
                }
            }
        } else {
            SALogDebug(@"showUpWebView: not valid webview");
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    } @finally {
        return YES;
    }
}

- (BOOL)shouldHandleWebView:(id)webView request:(NSURLRequest *)request {
    if (webView == nil) {
        SALogDebug(@"showUpWebView == nil");
        return NO;
    }

    if (request == nil || ![request isKindOfClass:NSURLRequest.class]) {
        SALogDebug(@"request == nil or not NSURLRequest class");
        return NO;
    }

    NSString *urlString = request.URL.absoluteString;
    if ([urlString rangeOfString:kSAJSGetAppInfoScheme].length ||[urlString rangeOfString:kSAJSTrackEventNativeScheme].length) {
        return YES;
    }
    return NO;
}

- (NSDictionary *)webViewJavascriptBridgeCallbackInfo {
    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    [libProperties setValue:@"iOS" forKey:SA_EVENT_TYPE];
    if (self.loginId != nil) {
        [libProperties setValue:self.loginId forKey:SA_EVENT_DISTINCT_ID];
        [libProperties setValue:[NSNumber numberWithBool:YES] forKey:@"is_login"];
    } else{
        [libProperties setValue:self.anonymousId forKey:SA_EVENT_DISTINCT_ID];
        [libProperties setValue:[NSNumber numberWithBool:NO] forKey:@"is_login"];
    }
    return [libProperties copy];
}


@end
