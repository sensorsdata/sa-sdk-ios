//
//  SAAuxiliaryToolManager.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/7.
//  Copyright © 2015－2018 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SAAuxiliaryToolManager.h"
#import "SensorsAnalyticsSDK.h"
#import "SALog.h"
#import "SAAlertController.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAVisualizedUtils.h"
#import "SAURLUtils.h"

@interface SAAuxiliaryToolManager()
@property (nonatomic, strong) SAVisualizedConnection *visualizedConnection;
@property (nonatomic, copy) NSString *postUrl;
@property (nonatomic, copy) NSString *featureCode;
@property (nonatomic, strong) NSURL *originalURL;
@property (nonatomic, copy) NSString *project;
@property (nonatomic, copy) NSString *host;

/// 当前类型
@property (nonatomic, assign) SensorsAnalyticsVisualizedType visualizedType;
@end
@implementation SAAuxiliaryToolManager
+ (instancetype)sharedInstance {
    static SAAuxiliaryToolManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SAAuxiliaryToolManager alloc] init];
    });
    return sharedInstance;
}

- (BOOL)canHandleURL:(NSURL *)URL {
    return [self isHeatMapURL:URL] || [self isVisualizedAutoTrackURL:URL] || [self isDebugModeURL:URL] || [self isSecretKeyURL:URL];
}

// 可视化全埋点 & 点击图 参数个接口判断
- (BOOL)handleURL:(NSURL *)URL isWifi:(BOOL)isWifi {
    if ([self canHandleURL:URL] == NO) {
        return NO;
    }

    NSDictionary *queryItems = [SAURLUtils decodeRueryItemsWithURL:URL];
    NSString *featureCode = queryItems[@"feature_code"];
    NSString *postURLStr = queryItems[@"url"];

    // project 和 host 不同
    NSString *project = [SAURLUtils queryItemsWithURLString:postURLStr][@"project"] ?: @"default";
    BOOL isEqualProject = [[SensorsAnalyticsSDK sharedInstance].network.project isEqualToString:project];
    if (!isEqualProject) {
        if ([self isHeatMapURL:URL]) {
            [self showAlterViewWithTitle:@"提示" message:@"App 集成的项目与电脑浏览器打开的项目不同，无法进行点击分析"];
        } else if([self isVisualizedAutoTrackURL:URL]){
            [self showAlterViewWithTitle:@"提示" message:@"App 集成的项目与电脑浏览器打开的项目不同，无法进行可视化全埋点"];
        }
        return YES;
    // 未开启点击图
    } else if ([self isHeatMapURL:URL] && ![[SensorsAnalyticsSDK sharedInstance] isHeatMapEnabled]) {
        [self showAlterViewWithTitle:@"提示" message:@"SDK 没有被正确集成，请联系贵方技术人员开启点击分析"];
        return YES;
    // 未开启可视化全埋点
    } else if ([self isVisualizedAutoTrackURL:URL] && ![[SensorsAnalyticsSDK sharedInstance] isVisualizedAutoTrackEnabled]) {
        [self showAlterViewWithTitle:@"提示" message:@"SDK 没有被正确集成，请联系贵方技术人员开启可视化全埋点"];
        return YES;
    } else if (featureCode && postURLStr) {
        [self showOpenDialogWithURL:URL featureCode:featureCode postURL:postURLStr isWifi:isWifi];
        return YES;
    } else { //feature_code url 参数错误
        [self showParameterError:@"ERROR" message:@"参数错误"];
        return NO;
    }
    return NO;
}

- (void)showOpenDialogWithURL:(NSURL *)URL featureCode:(NSString *)featureCode postURL:(NSString *)postURL isWifi:(BOOL)isWifi {
    self.featureCode = featureCode;
    self.postUrl = postURL;
    self.originalURL = URL;
    NSString *alertTitle = @"提示";
    NSString *alertMessage = [self alertMessageWithURL:URL isWifi:isWifi];

    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:alertTitle message:alertMessage preferredStyle:SAAlertControllerStyleAlert];

    [alertController addActionWithTitle:@"取消" style:SAAlertActionStyleCancel handler:^(SAAlertAction *_Nonnull action) {
        [self.visualizedConnection close];
        self.visualizedConnection = nil;
    }];

    [alertController addActionWithTitle:@"继续" style:SAAlertActionStyleDefault handler:^(SAAlertAction *_Nonnull action) {
        // 关闭之前的连接
        [self.visualizedConnection close];
        // start
        self.visualizedConnection = [[SAVisualizedConnection alloc] initWithURL:nil];
        if ([self isHeatMapURL:URL]) {
            SALogDebug(@"Confirmed to open HeatMap ...");
            self.visualizedType = SensorsAnalyticsVisualizedTypeHeatMap;
        } else if ([self isVisualizedAutoTrackURL:URL]) {
            SALogDebug(@"Confirmed to open VisualizedAutoTrack ...");
            self.visualizedType = SensorsAnalyticsVisualizedTypeAutoTrack;
        }
        [self.visualizedConnection startConnectionWithFeatureCode:featureCode url:postURL];
    }];

    [alertController show];
}

/// 是否正在进行可视化全埋点连接
- (BOOL)isVisualizedConnecting {
    return self.visualizedConnection.isVisualizedConnecting;
}
- (NSString *)alertMessageWithURL:(NSURL *)URL isWifi:(BOOL)isWifi {
    NSString *alertMessage = nil;
    if ([self isHeatMapURL:URL]) {
        alertMessage = @"正在连接 App 点击分析";
    } else if ([self isVisualizedAutoTrackURL:URL]) {
        alertMessage = @"正在连接 App 可视化全埋点";
    }
    if (!isWifi && alertMessage) {
        alertMessage = [alertMessage stringByAppendingString: @"，建议在 WiFi 环境下使用"];
    }
    return alertMessage;
}

- (BOOL)isHeatMapURL:(NSURL *)url {
    return [url.host isEqualToString:@"heatmap"];
}

- (BOOL)isVisualizedAutoTrackURL:(NSURL *)url {
    return [url.host isEqualToString:@"visualized"];
}

- (BOOL)isDebugModeURL:(NSURL *)url {
     return [url.host isEqualToString:@"debugmode"];
}

- (BOOL)isSecretKeyURL:(NSURL *)url {
     return [url.host isEqualToString:@"encrypt"];
}

- (void)showParameterError:(NSString *)alertTitle message:(NSString *)alertMessage {
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:alertTitle message:alertMessage preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"OK" style:SAAlertActionStyleDefault handler:^(SAAlertAction *_Nonnull action) {
    }];
    [alertController show];
}

- (void)showAlterViewWithTitle:(NSString *)title message:(NSString *)message {
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:message preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleDefault handler:nil];
    [alertController show];
}
@end
