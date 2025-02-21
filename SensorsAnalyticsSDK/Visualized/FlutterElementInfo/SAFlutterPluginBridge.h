//
// SAFlutterPluginBridge.h
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/7/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// SA 和 Flutter Plugin 的桥接通信
@interface SAFlutterPluginBridge : NSObject

+ (instancetype)sharedInstance;

/// 修改可视化全埋点连接状态
/// @param isConnectioned 是否连接
- (void)changeVisualConnectionStatus:(BOOL) isConnectioned;

/// 修改可视化全埋点连接状态
/// @param propertiesConfig 自定义属性配置
- (void)changeVisualPropertiesConfig:(NSDictionary *)propertiesConfig;

/// 获取可视化全埋点连接状态
/// @return 是否连接
- (BOOL)isVisualConnectioned;

/// 获取可视化全埋点自定义属性配置
///
/// 经过了 base64 编码，防止转义问题
///
/// @return 自定义属性配置
- (NSString *)visualPropertiesConfig;

/// 更新 Flutter 页面元素信息
/// @param jsonString 页面元素信息 json
- (void)updateFlutterElementInfo:(NSString *)jsonString;
@end

NS_ASSUME_NONNULL_END
