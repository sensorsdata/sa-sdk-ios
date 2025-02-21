//
// SAVisualizedAutoTrackConnection.h
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/9/4.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>



@protocol SAVisualizedMessage;

@interface SAVisualizedConnection : NSObject

@property (nonatomic, readonly) BOOL connected;

- (void)sendMessage:(id<SAVisualizedMessage>)message;
- (void)startConnectionWithFeatureCode:(NSString *)featureCode url:(NSString *)urlStr;
- (void)close;

// 是否正在进行可视化全埋点上传页面信息
- (BOOL)isVisualizedConnecting;
@end
