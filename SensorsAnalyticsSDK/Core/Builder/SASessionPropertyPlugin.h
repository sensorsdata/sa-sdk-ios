//
// SASessionPropertyPlugin.h
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/5.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPropertyPlugin.h"
#import "SASessionProperty.h"


NS_ASSUME_NONNULL_BEGIN

/// session 采集属性插件
@interface SASessionPropertyPlugin : SAPropertyPlugin

/// session 采集属性插件初始化
/// @param sessionProperty session 处理
- (instancetype)initWithSessionProperty:(SASessionProperty *)sessionProperty NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
