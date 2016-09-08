//
//  JSCallOCViewController.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 16/9/6.
//  Copyright © 2016年 SensorsData. All rights reserved.
//

#import "JSCallOCViewController.h"
#import "SensorsAnalyticsSDK.h"

@implementation JSCallOCViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.title = @"UIWebView";

    NSString *path = [[[NSBundle mainBundle] bundlePath]  stringByAppendingPathComponent:@"JSCallOC.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
    [webView loadRequest:request];

    webView.delegate = self;

    [self.view addSubview:webView];

//    //网址
//    NSString *httpStr=@"http://192.168.199.231:8080/index.html";
//    NSURL *httpUrl=[NSURL URLWithString:httpStr];
//    NSURLRequest *httpRequest=[NSURLRequest requestWithURL:httpUrl];
//    [self.webView loadRequest:httpRequest];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[SensorsAnalyticsSDK sharedInstance] showUpWebView:webView];
}

@end
