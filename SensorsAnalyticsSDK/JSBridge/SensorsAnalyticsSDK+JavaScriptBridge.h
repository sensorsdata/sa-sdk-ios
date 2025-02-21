//
// SensorsAnalyticsSDK+JavaScriptBridge.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/13.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SensorsAnalyticsSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK (JavaScriptBridge)

- (void)trackFromH5WithEvent:(NSString *)eventInfo;

- (void)trackFromH5WithEvent:(NSString *)eventInfo enableVerify:(BOOL)enableVerify;

@end

@interface SAConfigOptions (JavaScriptBridge)

/// 是否开启 WKWebView 的 H5 打通功能，该功能默认是关闭的
@property (nonatomic) BOOL enableJavaScriptBridge;

@end

NS_ASSUME_NONNULL_END
