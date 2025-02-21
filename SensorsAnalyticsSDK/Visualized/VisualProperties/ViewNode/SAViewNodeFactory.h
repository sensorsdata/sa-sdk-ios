//
// SAViewNodeFactory.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SAViewNode.h"

NS_ASSUME_NONNULL_BEGIN

/// 构造工厂
@interface SAViewNodeFactory : NSObject

+ (nullable SAViewNode *)viewNodeWithView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
