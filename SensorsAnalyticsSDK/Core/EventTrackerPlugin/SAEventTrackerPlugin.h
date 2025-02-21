//
// SAEventTrackerPlugin.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/11/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAEventTrackerPlugin : NSObject

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, assign) BOOL enable;

@end

NS_ASSUME_NONNULL_END
