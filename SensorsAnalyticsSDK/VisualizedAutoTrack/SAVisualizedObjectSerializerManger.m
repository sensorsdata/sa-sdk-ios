//
// SAVisualizedObjectSerializerManger.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/4/23.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAVisualizedObjectSerializerManger.h"
#import "SAJSONUtil.h"
#import "SALog.h"

@implementation SAVisualizedWebPageInfo

@end


@interface SAVisualizedObjectSerializerManger()

@property (nonatomic, strong) SAJSONUtil *jsonUtil;
/// 是否包含 webview
@property (nonatomic, assign, readwrite) BOOL isContainWebView;

/// App 内嵌 H5 页面信息
@property (nonatomic, strong, readwrite) SAVisualizedWebPageInfo *webPageInfo;

/// 截图 hash 更新信息，如果存在，则添加到 image_hash 后缀
@property (nonatomic, copy, readwrite) NSString *imageHashUpdateMessage;

/// 上次截图 hash
@property (nonatomic, copy, readwrite) NSString *lastImageHash;

/// 保存不同 controller 可点击元素个数
@property (nonatomic, copy) NSMapTable <UIViewController *, NSNumber *> *controllerCountMap;

/// 弹框信息
@property (nonatomic, strong, readwrite) NSMutableArray *alertInfos;

///  App 内嵌 H5 页面 缓存
/*
 key:H5 页面 url
 value:SAVisualizedWebPageInfo 对象
 */
@property (nonatomic, strong) NSCache <NSString *,SAVisualizedWebPageInfo *>*webPageInfoCache;

@end

@implementation SAVisualizedObjectSerializerManger

+ (instancetype)sharedInstance {
    static SAVisualizedObjectSerializerManger *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SAVisualizedObjectSerializerManger alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initializeObjectSerializer];
    }
    return self;
}

- (void)initializeObjectSerializer {
    _controllerCountMap = [NSMapTable weakToStrongObjectsMapTable];
    _alertInfos = [NSMutableArray array];
    _webPageInfoCache = [[NSCache alloc] init];
    _jsonUtil = [[SAJSONUtil alloc] init];
    [self resetObjectSerializer];
}

/// 重置解析配置
- (void)resetObjectSerializer {
    self.isContainWebView = NO;
    [self.controllerCountMap removeAllObjects];

    self.webPageInfo = nil;
    [self.alertInfos removeAllObjects];
}

- (void)cleanVisualizedWebPageInfoCache {
    [self.webPageInfoCache removeAllObjects];

    self.imageHashUpdateMessage = nil;
    self.lastImageHash = nil;
}

/// 刷新截图 imageHash 信息
- (void)refreshImageHashWithData:(id)obj {
    /*
      App 内嵌 H5 的可视化全埋点，可能页面加载完成，但是未及时接收到 Html 页面信息。
      等接收到 JS SDK 发送的页面信息，由于页面截图不变，前端页面未重新加载解析 viewTree 信息，导致无法圈选。
      所以，接收到 JS 的页面信息，在原有 imageHash 基础上拼接 html 页面数据 hash 值，使得前端重新加载页面信息
      */
    NSData *jsonData = nil;
    @try {
        jsonData = [self.jsonUtil JSONSerializeObject:obj];
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }

    if (jsonData) {
        NSUInteger hashCode = [jsonData hash];
        self.imageHashUpdateMessage = [NSString stringWithFormat:@"%lu", (unsigned long)hashCode];
    }
}

/// 缓存可视化全埋点相关 web 信息
- (void)saveVisualizedWebPageInfoWithWebView:(WKWebView *)webview webPageInfo:(NSDictionary *)pageInfo {

    NSString *callType = pageInfo[@"callType"];
    if (([callType isEqualToString:@"visualized_track"])) {
        // H5 页面可点击元素数据
        NSArray *pageDatas = pageInfo[@"data"];
        if ([pageDatas isKindOfClass:NSArray.class]) {
            NSDictionary *elementInfo = [pageDatas firstObject];
            NSString *url = elementInfo[@"$url"];
            if (url) {
                SAVisualizedWebPageInfo *webPageInfo = [[SAVisualizedWebPageInfo alloc] init];
                // 是否包含当前 url 的页面信息
                if ([self.webPageInfoCache objectForKey:url]) {
                    webPageInfo = [self.webPageInfoCache objectForKey:url];

                    // 更新 H5 元素信息，则可视化全埋点可用，此时清空弹框信息
                    webPageInfo.alertSources = nil;
                }
                webPageInfo.elementSources = pageDatas;
                [self.webPageInfoCache setObject:webPageInfo forKey:url];

                // 刷新数据
                [self refreshImageHashWithData:pageDatas];
            }
        }
    } else if ([callType isEqualToString:@"app_alert"]) { // 弹框提示信息
        /*
         [{
         "title": "弹框标题",
         "message": "App SDK 与 Web SDK 没有进行打通，请联系贵方技术人员修正 Web SDK 的配置，详细信息请查看文档。",
         "link_text": "配置文档"
         "link_url": "https://manual.sensorsdata.cn/sa/latest/app-h5-1573913.html"
         }]
         */
        NSArray <NSDictionary *> *alertDatas = pageInfo[@"data"];
        NSString *url = webview.URL.absoluteString;
        if ([alertDatas isKindOfClass:NSArray.class] && url) {
            SAVisualizedWebPageInfo *webPageInfo = [[SAVisualizedWebPageInfo alloc] init];
            // 是否包含当前 url 的页面信息
            if ([self.webPageInfoCache objectForKey:url]) {
                webPageInfo = [self.webPageInfoCache objectForKey:url];

                // 如果 js 发送弹框信息，即 js 环境变化，可视化全埋点不可用，则清空页面信息
                webPageInfo.elementSources = nil;
                webPageInfo.url = nil;
                webPageInfo.title = nil;
            }
            webPageInfo.alertSources = alertDatas;

            [self.webPageInfoCache setObject:webPageInfo forKey:url];
            // 刷新数据
            [self refreshImageHashWithData:alertDatas];
        }
    } else if (([callType isEqualToString:@"page_info"])) { // h5 页面信息
        NSDictionary *webInfo = pageInfo[@"data"];
        NSString *url = webInfo[@"$url"];
        if ([webInfo isKindOfClass:NSDictionary.class] && url) {
            SAVisualizedWebPageInfo *webPageInfo = [[SAVisualizedWebPageInfo alloc] init];
            // 是否包含当前 url 的页面信息
            if ([self.webPageInfoCache objectForKey:url]) {
                webPageInfo = [self.webPageInfoCache objectForKey:url];

                // 更新 H5 页面信息，则可视化全埋点可用，此时清空弹框信息
                webPageInfo.alertSources = nil;
            }
            webPageInfo.url = url;
            webPageInfo.title = webInfo[@"$title"];
            [self.webPageInfoCache setObject:webPageInfo forKey:url];

            // 刷新数据
            [self refreshImageHashWithData:webInfo];
        }
    }
}

/// 读取当前 webView 页面信息
- (SAVisualizedWebPageInfo *)readWebPageInfoWithWebView:(WKWebView *)webView {
    NSString *url = webView.URL.absoluteString;
    SAVisualizedWebPageInfo *webPageInfo = [self.webPageInfoCache objectForKey:url];
    return webPageInfo;
}

- (void)enterWebViewPageWithWebInfo:(SAVisualizedWebPageInfo *)webInfo; {
    self.isContainWebView = YES;
    if (webInfo) {
        self.webPageInfo = webInfo;
    }
}

/// 进入页面
- (void)enterViewController:(UIViewController *)viewController {
    NSNumber *countNumber = [self.controllerCountMap objectForKey:viewController];
    if (countNumber) {
        NSInteger countValue = [countNumber integerValue];
        [self.controllerCountMap setObject:@(countValue + 1) forKey:viewController];
    } else {
        [self.controllerCountMap setObject:@(1) forKey:viewController];
    }
}

- (void)resetLastImageHash:(NSString *)imageHash {
    self.lastImageHash = imageHash;
    self.imageHashUpdateMessage = nil;
}

- (UIViewController *)currentViewController {
    NSArray <UIViewController *>*allViewControllers = NSAllMapTableKeys(self.controllerCountMap);
    UIViewController *mostShowViewController = nil;
    NSInteger mostShowCount = 1;
    for (UIViewController *controller in allViewControllers) {
        NSNumber *countNumber = [self.controllerCountMap objectForKey:controller];
        if (countNumber.integerValue >= mostShowCount) {
            mostShowCount = countNumber.integerValue;
            mostShowViewController = controller;
        }
    }
    return mostShowViewController;
}

- (void)registWebAlertInfos:(NSArray <NSDictionary *> *)infos {
    if (infos.count == 0) {
        return;
    }
    // 通过 Dictionary 构造所有不同 message 的弹框集合
    NSMutableDictionary *alertMessageInfoDic = [NSMutableDictionary dictionary];
    for (NSDictionary *alertInfo in self.alertInfos) {
        NSString *message = alertInfo[@"message"];
        if (message) {
            alertMessageInfoDic[message] = alertInfo;
        }
    }

    // 只添加 message 不重复的弹框信息
    for (NSDictionary *alertInfo in infos) {
        NSString *message = alertInfo[@"message"];
        if (message && ![alertMessageInfoDic.allKeys containsObject:message]) {
            [self.alertInfos addObject:alertInfo];
        }
    }

    // 强制刷新数据
    [self refreshImageHashWithData:infos];
}
@end
