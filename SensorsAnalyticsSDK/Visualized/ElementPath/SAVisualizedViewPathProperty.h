//
// SAVisualizedViewPathProperty.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/28.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//


#import <Foundation/Foundation.h>


#pragma mark - Visualized
// 可视化全埋点&点击分析 上传页面信息相关协议
@protocol SAVisualizedViewPathProperty <NSObject>

@optional
/// 当前元素，前端是否渲染成可交互
@property (nonatomic, assign, readonly) BOOL sensorsdata_enableAppClick;

/// 当前元素的有效内容
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementValidContent;

/// 元素子视图
@property (nonatomic, copy, readonly) NSArray *sensorsdata_subElements;

/// App 内嵌 H5 元素的元素选择器
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementSelector;

/// 相对 keywindow 的坐标
@property (nonatomic, assign, readonly) CGRect sensorsdata_frame;

/// 当前元素所在页面名称
@property (nonatomic, copy, readonly) NSString *sensorsdata_screenName;

/// 当前元素所在页面标题
@property (nonatomic, copy, readonly) NSString *sensorsdata_title;

/// 是否为 Web 元素
@property (nonatomic, assign) BOOL sensorsdata_isFromWeb;

/// 是否为列表（本身支持限定位置，比如 Cell）
@property (nonatomic, assign) BOOL sensorsdata_isListView;

/// 元素所在平台
///
/// 区分不同平台的元素（ios/h5/flutter）,Flutter 和其他平台，不支持混合圈选（事件和属性元素属于不同平台），需要给予屏蔽
@property (nonatomic, copy) NSString *sensorsdata_platform;


@end

#pragma mark - Extension
@protocol SAVisualizedExtensionProperty <NSObject>

@optional
/// 一个 view 上子视图可见区域
@property (nonatomic, assign, readonly) CGRect sensorsdata_visibleFrame;

/// 是否禁用 RCTView 子视图交互
@property (nonatomic, assign) BOOL sensorsdata_isDisableRNSubviewsInteractive;
@end
