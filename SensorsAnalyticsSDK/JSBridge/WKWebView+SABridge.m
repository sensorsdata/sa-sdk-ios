//
// WKWebView+SABridge.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/3/21.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "WKWebView+SABridge.h"
#import "SAJavaScriptBridgeManager.h"

@implementation WKWebView (SABridge)

- (WKNavigation *)sensorsdata_loadRequest:(NSURLRequest *)request {
    [[SAJavaScriptBridgeManager defaultManager] addScriptMessageHandlerWithWebView:self];
    
    return [self sensorsdata_loadRequest:request];
}

- (WKNavigation *)sensorsdata_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    [[SAJavaScriptBridgeManager defaultManager] addScriptMessageHandlerWithWebView:self];
    
    return [self sensorsdata_loadHTMLString:string baseURL:baseURL];
}

- (WKNavigation *)sensorsdata_loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL {
    [[SAJavaScriptBridgeManager defaultManager] addScriptMessageHandlerWithWebView:self];
    
    return [self sensorsdata_loadFileURL:URL allowingReadAccessToURL:readAccessURL];
}

- (WKNavigation *)sensorsdata_loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL {
    [[SAJavaScriptBridgeManager defaultManager] addScriptMessageHandlerWithWebView:self];
    
    return [self sensorsdata_loadData:data MIMEType:MIMEType characterEncodingName:characterEncodingName baseURL:baseURL];
}

@end
