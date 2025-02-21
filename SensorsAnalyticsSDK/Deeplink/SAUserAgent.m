//
// SAUserAgent.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/8/19.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAUserAgent.h"
#import <WebKit/WKWebView.h>
#import "SALog.h"

@interface SAUserAgent ()

@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) dispatch_group_t loadUAGroup;
@property (nonatomic, copy) NSString* userAgent;

@end

@implementation SAUserAgent

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAUserAgent *userAgent;
    dispatch_once(&onceToken, ^{
        userAgent = [[SAUserAgent alloc] init];
    });
    return userAgent;
}

+ (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion {
    [[SAUserAgent sharedInstance] loadUserAgentWithCompletion:completion];
}

- (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.userAgent.length > 0) {
            completion(self.userAgent);
        } else if (self.wkWebView) {
            dispatch_group_notify(self.loadUAGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                completion(self.userAgent);
            });
        } else {
            self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
            self.loadUAGroup = dispatch_group_create();
            dispatch_group_enter(self.loadUAGroup);

            __weak typeof(self) weakSelf = self;
            [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;

                if (error || !response) {
                    SALogError(@"WKWebView evaluateJavaScript load UA error:%@", error);
                    completion(nil);
                } else {
                    completion(response);
                    strongSelf.userAgent = response;
                }
                // 通过 wkWebView 控制 dispatch_group_leave 的次数
                if (strongSelf.wkWebView) {
                    dispatch_group_leave(strongSelf.loadUAGroup);
                }
                strongSelf.wkWebView = nil;
            }];
        }
    });
}

@end
