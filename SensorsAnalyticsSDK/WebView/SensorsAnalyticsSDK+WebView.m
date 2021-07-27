//
// SensorsAnalyticsSDK+SAWebView.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/8/12.
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

#if __has_include("SensorsAnalyticsSDK+WKWebView.h")
#error This file cannot exist at the same time with `SensorsAnalyticsSDK+WKWebView.h`. If you use `UIWebView`, please delete it.
#endif

#import "SensorsAnalyticsSDK+WebView.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"
#import "SACommonUtility.h"
#import "SAConstants.h"
#import "SAJSONUtil.h"
#import "SAURLUtils.h"
#import "SALog.h"

static NSString * const kSAJSGetAppInfoScheme = @"sensorsanalytics://getAppInfo";
static NSString * const kSAJSTrackEventNativeScheme = @"sensorsanalytics://trackEvent";

@interface SensorsAnalyticsSDK (SAWebViewPrivate)

@property (atomic, copy) NSString *userAgent;
@property (nonatomic, copy) NSString *addWebViewUserAgent;

@property (nonatomic, strong) SANetwork *network;

@end

@implementation SensorsAnalyticsSDK (WebView)

- (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion {
    if (self.userAgent) {
        return completion(self.userAgent);
    }
    [SACommonUtility performBlockOnMainThread:^{
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        self.userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        completion(self.userAgent);
    }];
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
        NSData *jsonData = [SAJSONUtil dataWithJSONObject:properties];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        NSString *js = [NSString stringWithFormat:@"sensorsdata_app_js_bridge_call_js('%@')", jsonString];

        NSString *urlstr = request.URL.absoluteString;
        if (!urlstr) {
            return YES;
        }

        //解析参数
        NSMutableDictionary *paramsDic = [[SAURLUtils queryItemsWithURLString:urlstr] mutableCopy];

        if ([webView isKindOfClass:[UIWebView class]]) {//UIWebView
            SALogDebug(@"showUpWebView: UIWebView");
            if ([urlstr rangeOfString:kSAJSGetAppInfoScheme].location != NSNotFound) {
                [webView stringByEvaluatingJavaScriptFromString:js];
            } else if ([urlstr rangeOfString:kSAJSTrackEventNativeScheme].location != NSNotFound) {
                if ([paramsDic count] > 0) {
                    NSString *eventInfo = [paramsDic objectForKey:kSAEventName];
                    if (eventInfo != nil) {
                        NSString *encodedString = [eventInfo stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [self trackFromH5WithEvent:encodedString enableVerify:enableVerify];
                    }
                }
            }
        } else if ([webView isKindOfClass:[WKWebView class]]) {//WKWebView
            SALogDebug(@"showUpWebView: WKWebView");
            if ([urlstr rangeOfString:kSAJSGetAppInfoScheme].location != NSNotFound) {
                [(WKWebView *)webView evaluateJavaScript:js completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                    SALogDebug(@"response: %@ error: %@", response, error);
                }];
            } else if ([urlstr rangeOfString:kSAJSTrackEventNativeScheme].location != NSNotFound) {
                if ([paramsDic count] > 0) {
                    NSString *eventInfo = [paramsDic objectForKey:kSAEventName];
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
    [libProperties setValue:@"iOS" forKey:kSAEventType];
    if (self.loginId != nil) {
        [libProperties setValue:self.loginId forKey:kSAEventDistinctId];
        [libProperties setValue:[NSNumber numberWithBool:YES] forKey:@"is_login"];
    } else{
        [libProperties setValue:self.anonymousId forKey:kSAEventDistinctId];
        [libProperties setValue:[NSNumber numberWithBool:NO] forKey:@"is_login"];
    }
    return [libProperties copy];
}

@end
