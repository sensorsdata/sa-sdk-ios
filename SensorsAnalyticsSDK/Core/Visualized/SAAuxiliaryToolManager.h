//
//  SAAuxiliaryToolManager.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/7.
//  Copyright © 2015－2018 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAVisualizedConnection.h"


typedef NS_ENUM(NSInteger, SensorsAnalyticsVisualizedType) {
    SensorsAnalyticsVisualizedTypeUnkhow,  // 未知或不允许
    SensorsAnalyticsVisualizedTypeHeatMap, // 点击图
    SensorsAnalyticsVisualizedTypeAutoTrack  //可视化全埋点
};

NS_ASSUME_NONNULL_BEGIN

@interface SAAuxiliaryToolManager : NSObject

@property (nonatomic, assign, readonly) SensorsAnalyticsVisualizedType visualizedType;

+ (instancetype)sharedInstance;

- (BOOL)canHandleURL:(NSURL *)url;
- (BOOL)handleURL:(NSURL *)url  isWifi:(BOOL)isWifi;

- (BOOL)isHeatMapURL:(NSURL *)url;
- (BOOL)isVisualizedAutoTrackURL:(NSURL *)url;
- (BOOL)isDebugModeURL:(NSURL *)url;
- (BOOL)isSecretKeyURL:(NSURL *)url;

/// 是否正在进行 可视化全埋点/点击分析 连接
- (BOOL)isVisualizedConnecting;
@end

NS_ASSUME_NONNULL_END
