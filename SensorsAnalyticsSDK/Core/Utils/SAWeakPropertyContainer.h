//
// SAWeakPropertyContainer.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2019/8/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SAWeakPropertyContainer : NSObject

@property (readonly, nonatomic, weak) id weakProperty;

+ (instancetype)containerWithWeakProperty:(id)weakProperty;

@end
