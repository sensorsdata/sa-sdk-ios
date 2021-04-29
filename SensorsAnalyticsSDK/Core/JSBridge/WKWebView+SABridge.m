//
// WKWebView+SABridge.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/3/21.
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

#import "WKWebView+SABridge.h"
#import "SensorsAnalyticsSDK+Private.h"

@implementation WKWebView (SABridge)

- (WKNavigation *)sensorsdata_loadRequest:(NSURLRequest *)request {
    [[SensorsAnalyticsSDK sharedInstance] addScriptMessageHandlerWithWebView:self];
    
    return [self sensorsdata_loadRequest:request];
}

- (WKNavigation *)sensorsdata_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    [[SensorsAnalyticsSDK sharedInstance] addScriptMessageHandlerWithWebView:self];
    
    return [self sensorsdata_loadHTMLString:string baseURL:baseURL];
}

- (WKNavigation *)sensorsdata_loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL {
    [[SensorsAnalyticsSDK sharedInstance] addScriptMessageHandlerWithWebView:self];
    
    return [self sensorsdata_loadFileURL:URL allowingReadAccessToURL:readAccessURL];
}

- (WKNavigation *)sensorsdata_loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL {
    [[SensorsAnalyticsSDK sharedInstance] addScriptMessageHandlerWithWebView:self];
    
    return [self sensorsdata_loadData:data MIMEType:MIMEType characterEncodingName:characterEncodingName baseURL:baseURL];
}

@end
