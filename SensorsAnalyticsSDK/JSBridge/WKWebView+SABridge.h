//
// WKWebView+SABridge.h
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

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (SABridge)

- (WKNavigation *)sensorsdata_loadRequest:(NSURLRequest *)request;

- (WKNavigation *)sensorsdata_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

- (WKNavigation *)sensorsdata_loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL;

- (WKNavigation *)sensorsdata_loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL;

@end

NS_ASSUME_NONNULL_END
