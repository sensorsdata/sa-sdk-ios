//
//  WebViewController.m
//  example-macOS
//
//  Created by 陈玉国 on 2025/3/7.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>

@interface WebViewController ()

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:[[WKWebViewConfiguration alloc] init]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://jssdk.debugbox.sensorsdata.cn/js/cqs/sa-demo/callJS.html"]]];
    [self.view addSubview:self.webView];
}

@end
