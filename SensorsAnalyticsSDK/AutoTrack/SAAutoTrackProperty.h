//
// SAAutoTrackProperty.h
// SensorsAnalyticsSDK
//
// Created by 张敏超 on 2019/4/23.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
    

#import <Foundation/Foundation.h>

@protocol SAAutoTrackViewControllerProperty <NSObject>

@property (nonatomic, readonly) BOOL sensorsdata_isIgnored;

@end

#pragma mark -
@protocol SAAutoTrackViewProperty <NSObject>

@property (nonatomic, readonly) BOOL sensorsdata_isIgnored;
/// 记录上次触发点击事件的开机时间
@property (nonatomic, assign) NSTimeInterval sensorsdata_timeIntervalForLastAppClick;

@end
