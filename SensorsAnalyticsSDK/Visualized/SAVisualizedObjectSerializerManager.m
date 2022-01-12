//
// SAVisualizedObjectSerializerManager.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/4/23.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAVisualizedObjectSerializerManager.h"
#import "SAJSONUtil.h"
#import "SALog.h"
#import "SAVisualizedManager.h"
#import "SACommonUtility.h"

@implementation SAVisualizedWebPageInfo

@end


@interface SAVisualizedObjectSerializerManager()

/// 是否包含 webview
@property (nonatomic, assign, readwrite) BOOL isContainWebView;

/// App 内嵌 H5 页面信息
@property (nonatomic, strong, readwrite) SAVisualizedWebPageInfo *webPageInfo;

/// payload 新增内容对应 hash，如果存在，则添加到 image_hash 后缀
@property (nonatomic, copy) NSString *jointPayloadHash;

/// 上次数据包标识 hash
@property (nonatomic, copy, readwrite) NSString *lastPayloadHash;

/// 记录当前栈中的 controller，不会持有
@property (nonatomic, strong) NSPointerArray *controllersStack;

/// 弹框信息
@property (nonatomic, strong, readwrite) NSMutableArray *alertInfos;

/// App 内嵌 H5 页面 缓存
/*
 key:H5 页面 url
 value:SAVisualizedWebPageInfo 对象
 */
@property (nonatomic, strong) NSMutableDictionary <NSString *,SAVisualizedWebPageInfo *>*webPageInfoCache;

@end

@implementation SAVisualizedObjectSerializerManager

+ (instancetype)sharedInstance {
    static SAVisualizedObjectSerializerManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SAVisualizedObjectSerializerManager alloc] init];
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

    /* NSPointerArray 使用 weakObjectsPointerArray 初始化
     对于集合中的对象不会强引用，如果对象被释放，则会被置为 NULL，调用 compact 即可移除所有 NULL 对象
     */
    _controllersStack = [NSPointerArray weakObjectsPointerArray];
    _alertInfos = [NSMutableArray array];
    _webPageInfoCache = [NSMutableDictionary dictionary];

    _isContainWebView = NO;
}

/// 重置解析配置
- (void)resetObjectSerializer {
    self.isContainWebView = NO;

    self.webPageInfo = nil;
    [self.alertInfos removeAllObjects];
}

#pragma mark WebInfo
- (void)cleanVisualizedWebPageInfoCache {
    [self.webPageInfoCache removeAllObjects];

    self.jointPayloadHash = nil;
    self.lastPayloadHash = nil;
}

/// 缓存可视化全埋点相关 web 信息
- (void)saveVisualizedWebPageInfoWithWebView:(WKWebView *)webview webPageInfo:(NSMutableDictionary *)pageInfo {

    NSString *callType = pageInfo[@"callType"];
    if ([callType isEqualToString:@"visualized_track"]) { // 页面元素信息

        [self saveWebElementInfoWithData:pageInfo webView:webview];
    } else if ([callType isEqualToString:@"app_alert"]) { // 弹框提示信息

        [self saveWebAlertInfoWithData:pageInfo webView:webview];

    } else if ([callType isEqualToString:@"page_info"]) { // h5 页面信息
        [self saveWebPageInfoWithData:pageInfo webView:webview];
    }

    // 刷新数据
    [self refreshPayloadHashWithData:pageInfo];
}

/// 保存 H5 元素信息，并设置状态
- (void)saveWebElementInfoWithData:(NSMutableDictionary *)pageInfo webView:(WKWebView *)webview {
    // H5 页面可点击元素数据
    NSArray *pageDatas = pageInfo[@"data"];
    // 老版本 Web JS SDK 兼容，老版不包含 enable_click 字段，可点击元素需要设置标识
    for (NSMutableDictionary *elementInfoDic in pageDatas) {
        elementInfoDic[@"enable_click"] = @YES;
    }

    // H5 页面可见非点击元素
    NSArray *extraElements = pageInfo[@"extra_elements"];

    if (pageDatas.count == 0 && extraElements.count == 0) {
        return;
    }
    NSMutableArray *webElementSources = [NSMutableArray array];
    if (pageDatas.count > 0) {
        [webElementSources addObjectsFromArray:pageDatas];
    }
    if (extraElements.count > 0) {
        [webElementSources addObjectsFromArray:extraElements];
    }

    NSDictionary *elementInfo = [webElementSources firstObject];
    NSString *url = elementInfo[@"$url"];
    if (!url) {
        return;
    }

    SAVisualizedWebPageInfo *webPageInfo = nil;
    // 是否包含当前 url 的页面信息
    if ([self.webPageInfoCache objectForKey:url]) {
        webPageInfo = self.webPageInfoCache[url];

        // 更新 H5 元素信息，则可视化全埋点可用，此时清空弹框信息
        webPageInfo.alertSources = nil;
    } else {
        webPageInfo = [[SAVisualizedWebPageInfo alloc] init];
        self.webPageInfoCache[url] = webPageInfo;
    }
    webPageInfo.webElementSources = [webElementSources copy];
}

/// 保存 H5 页面弹框信息
- (void)saveWebAlertInfoWithData:(NSDictionary *)pageInfo webView:(WKWebView *)webview {
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
    if (![alertDatas isKindOfClass:NSArray.class] || !url) {
        return;
    }

    SAVisualizedWebPageInfo *webPageInfo = nil;
    // 是否包含当前 url 的页面信息
    if ([self.webPageInfoCache objectForKey:url]) {
        webPageInfo = self.webPageInfoCache[url];

        // 如果 js 发送弹框信息，即 js 环境变化，可视化全埋点不可用，则清空页面信息
        webPageInfo.webElementSources = nil;
        webPageInfo.url = nil;
        webPageInfo.title = nil;
    } else {
        webPageInfo = [[SAVisualizedWebPageInfo alloc] init];
        self.webPageInfoCache[url] = webPageInfo;
    }

    // 区分点击分析和可视化全埋点，针对 JS 发送的弹框信息，截取标题替换处理
    if ([SAVisualizedManager defaultManager].visualizedType == SensorsAnalyticsVisualizedTypeHeatMap) {
        NSMutableArray <NSDictionary *>* alertNewDatas = [NSMutableArray array];
        for (NSDictionary *alertDic in alertDatas) {
            NSMutableDictionary <NSString *, NSString *>* alertNewDic = [NSMutableDictionary dictionaryWithDictionary:alertDic];
            alertNewDic[@"title"] = [alertDic[@"title"] stringByReplacingOccurrencesOfString:@"可视化全埋点" withString:@"点击分析"];
            [alertNewDatas addObject:alertNewDic];
        };
        alertDatas = [alertNewDatas copy];
    }
    webPageInfo.alertSources = alertDatas;
}

/// 保存 H5 页面信息
- (void)saveWebPageInfoWithData:(NSDictionary *)pageInfo webView:(WKWebView *)webview {
    NSDictionary *webInfo = pageInfo[@"data"];
    NSString *url = webInfo[@"$url"];
    NSString *libVersion = webInfo[@"lib_version"];

    if (![webInfo isKindOfClass:NSDictionary.class] || !url) {
        return;
    }
    SAVisualizedWebPageInfo *webPageInfo = nil;
    // 是否包含当前 url 的页面信息
    if ([self.webPageInfoCache objectForKey:url]) {
        webPageInfo = self.webPageInfoCache[url];
        // 更新 H5 页面信息，则可视化全埋点可用，此时清空弹框信息
        webPageInfo.alertSources = nil;
    } else {
        webPageInfo = [[SAVisualizedWebPageInfo alloc] init];
        self.webPageInfoCache[url] = webPageInfo;
    }

    webPageInfo.url = url;
    webPageInfo.title = webInfo[@"$title"];
    webPageInfo.webLibVersion = libVersion;
}

/// 读取当前 webView 页面相关信息
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
    [self refreshPayloadHashWithData:infos];
}

#pragma mark viewScreenController
/// 进入页面
- (void)enterViewController:(UIViewController *)viewController {
    [self removeAllNullInControllersStack];
    [self.controllersStack addPointer:(__bridge void * _Nullable)(viewController)];
}

- (UIViewController *)lastViewScreenController {
    // allObjects 会自动过滤 NULL
    if (self.controllersStack.allObjects.count == 0) {
        return nil;
    }
    UIViewController *lastVC = [self.controllersStack.allObjects lastObject];

    // 如果 viewController 不在屏幕显示就移除
    while (lastVC && !lastVC.view.window) {
        // 如果 count 不等，即 controllersStack 存在 NULL
        if (self.controllersStack.count > self.controllersStack.allObjects.count) {
            [self removeAllNullInControllersStack];
        }

        // 移除最后一个不显示的 viewController
        [self.controllersStack removePointerAtIndex:self.controllersStack.count - 1];
        if (self.controllersStack.allObjects.count == 0) {
            return nil;
        }
        lastVC = [self.controllersStack.allObjects lastObject];
    }
    return lastVC;
}

/// 移除 controllersStack 中所有 NULL
- (void)removeAllNullInControllersStack {
    // 每次 compact 之前需要添加 NULL，规避系统 Bug（compact 函数有个已经报备的 bug，每次 compact 之前需要添加一个 NULL，否则会 compact 失败）
    [self.controllersStack addPointer:NULL];
    [self.controllersStack compact];
}

#pragma mark payloadHash
/// 根据截图 hash 获取完整 PayloadHash
- (NSString *)fetchPayloadHashWithImageHash:(NSString *)imageHash {
    if (self.jointPayloadHash.length == 0) {
        return imageHash;
    }
    if (imageHash.length == 0) {
        return self.jointPayloadHash;
    }
    return [imageHash stringByAppendingString:self.jointPayloadHash];
}

- (void)resetLastPayloadHash:(NSString *)payloadHash {
    self.jointPayloadHash = nil;
    self.lastPayloadHash = payloadHash;
}

/// 刷新截图 imageHash 信息
- (void)refreshPayloadHashWithData:(id)obj {
    /*
     App 内嵌 H5 的可视化全埋点，可能页面加载完成，但是未及时接收到 Html 页面信息。
     等接收到 JS SDK 发送的页面信息，由于页面截图不变，前端页面未重新加载解析 viewTree 信息，导致无法圈选。
     所以，接收到 JS 的页面信息，在原有 imageHash 基础上拼接 html 页面数据 hash 值，使得前端重新加载页面信息
     */
    if (!obj) {
        return;
    }

    NSData *jsonData = [SAJSONUtil dataWithJSONObject:obj];
    if (jsonData) {
        // 计算 hash
        self.jointPayloadHash = [SACommonUtility hashStringWithData:jsonData];
    }
}

@end

