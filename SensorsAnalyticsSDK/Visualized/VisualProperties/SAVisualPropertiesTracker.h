//
// SAVisualPropertiesTracker.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SAVisualPropertiesConfigSources.h"
#import "SAViewNodeTree.h"

NS_ASSUME_NONNULL_BEGIN


@interface SAVisualPropertiesTracker : NSObject

- (instancetype)initWithConfigSources:(SAVisualPropertiesConfigSources *)configSources;

@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;

@property (atomic, strong, readonly) SAViewNodeTree *viewNodeTree;

#pragma mark view changed
/// 视图添加或移除
- (void)didMoveToSuperviewWithView:(UIView *)view;

- (void)didMoveToWindowWithView:(UIView *)view;

// 添加子视图
- (void)didAddSubview:(UIView *)subview;

/// 成为 keyWindow
- (void)becomeKeyWindow:(UIWindow *)window;

/// 进入 RN 的自定义 viewController
- (void)enterRNViewController:(UIViewController *)viewController;

#pragma mark visualProperties

/// 采集元素自定义属性
/// @param view 触发事件的元素
/// @param completionHandler 采集完成回调
- (void)visualPropertiesWithView:(UIView *)view completionHandler:(void (^)(NSDictionary *_Nullable visualProperties))completionHandler;


/// 根据配置，采集属性
/// @param propertyConfigs 自定义属性配置
/// @param completionHandler 采集完成回调
- (void)queryVisualPropertiesWithConfigs:(NSArray <NSDictionary *>*)propertyConfigs completionHandler:(void (^)(NSDictionary *_Nullable properties))completionHandler;

#pragma mark debugInfo
/// 设置采集诊断日志
- (void)enableCollectDebugLog:(BOOL)enable;

@property (nonatomic, copy, readonly) NSArray <NSDictionary *>*logInfos;


@end


NS_ASSUME_NONNULL_END
