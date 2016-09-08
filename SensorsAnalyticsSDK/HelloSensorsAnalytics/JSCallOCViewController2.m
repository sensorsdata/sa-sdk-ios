//
//  JSCallOCViewController2.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 16/9/6.
//  Copyright © 2016年 SensorsData. All rights reserved.
//

#import "JSCallOCViewController2.h"
#import "SensorsAnalyticsSDK.h"
@import WebKit;

@interface JSCallOCViewController2 ()
@property WKWebView *webView;
@end
@implementation JSCallOCViewController2
- (void)viewDidLoad
{
    [super viewDidLoad];
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.title = @"WKWebView";

    NSString *path = [[[NSBundle mainBundle] bundlePath]  stringByAppendingPathComponent:@"JSCallOC.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];

    [_webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];

    [self.view addSubview:_webView];

    //    //网址
    //    NSString *httpStr=@"http://192.168.199.231:8080/index.html";
    //    NSURL *httpUrl=[NSURL URLWithString:httpStr];
    //    NSURLRequest *httpRequest=[NSURLRequest requestWithURL:httpUrl];
    //    [self.webView loadRequest:httpRequest];

    [_webView loadRequest:request];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (!_webView.loading) {
        [[SensorsAnalyticsSDK sharedInstance] showUpWebView:_webView];
    }
}

-(void)dealloc {
    [_webView removeObserver:self forKeyPath:@"loading"];
}
@end
