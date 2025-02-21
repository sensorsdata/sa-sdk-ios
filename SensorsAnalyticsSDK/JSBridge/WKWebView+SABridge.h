//
// WKWebView+SABridge.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/3/21.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (SABridge)

- (WKNavigation *)sensorsdata_loadRequest:(NSURLRequest *)request;

- (WKNavigation *)sensorsdata_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

- (WKNavigation *)sensorsdata_loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL;

- (WKNavigation *)sensorsdata_loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL;

@end

NS_ASSUME_NONNULL_END
