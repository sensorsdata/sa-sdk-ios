//
//  JSCallOCViewController2.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 16/9/6.
//  Copyright © 2016年 SensorsData. All rights reserved.
//

#import "JSCallOCViewController2.h"
#import "SensorsAnalyticsSDK.h"
#import <WebKit/WebKit.h>

@interface JSCallOCViewController2 ()<WKNavigationDelegate, WKUIDelegate>
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
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;

    [self.view addSubview:_webView];

    //网址
//    NSString *httpStr=@"https://www.sensorsdata.cn/test/in.html";
//    NSURL *httpUrl=[NSURL URLWithString:httpStr];
//    NSURLRequest *request=[NSURLRequest requestWithURL:httpUrl];
    
    [self.webView loadRequest:request];

}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([[SensorsAnalyticsSDK sharedInstance] showUpWebView:webView WithRequest:navigationAction.request]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (!_webView.loading) {
        //[[SensorsAnalyticsSDK sharedInstance] showUpWebView:_webView];
    }
}

-(void)dealloc {
    [_webView removeObserver:self forKeyPath:@"loading"];
}
@end
