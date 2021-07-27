//
// SAJavaScriptBridgeManager.h
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

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAJavaScriptBridgeManager : NSObject <WKScriptMessageHandler, SAModuleProtocol, SAJavaScriptBridgeModuleProtocol>

@property (nonatomic, assign, getter=isEnable) BOOL enable;

@property (nonatomic, strong) SAConfigOptions *configOptions;

+ (instancetype)sharedInstance;

- (void)addScriptMessageHandlerWithWebView:(WKWebView *)webView;

@end

NS_ASSUME_NONNULL_END
