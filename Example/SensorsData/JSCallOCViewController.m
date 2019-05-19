//
//  JSCallOCViewController.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 16/9/6.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
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

#import "JSCallOCViewController.h"
#import <SensorsAnalyticsSDK/SensorsAnalyticsSDK.h>

@implementation JSCallOCViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.title = @"UIWebView";

    NSString *path = [[[NSBundle mainBundle] bundlePath]  stringByAppendingPathComponent:@"test2.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
    [webView loadRequest:request];

    webView.delegate = self;

    [self.view addSubview:webView];

//    //网址
//    NSString *httpStr=@"https://www.sensorsdata.cn/test/in.html";
//    NSURL *httpUrl=[NSURL URLWithString:httpStr];
//    NSURLRequest *request=[NSURLRequest requestWithURL:httpUrl];
    
    [webView loadRequest:request];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[SensorsAnalyticsSDK sharedInstance] showUpWebView:webView WithRequest:request enableVerify:YES]) {
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    //[[SensorsAnalyticsSDK sharedInstance] showUpWebView:webView];
}

@end
