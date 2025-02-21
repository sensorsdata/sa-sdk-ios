//
// SAWeakPropertyContainer.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2019/8/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAWeakPropertyContainer.h"

@interface SAWeakPropertyContainer ()
 
@property (nonatomic, weak) id weakProperty;

@end

@implementation SAWeakPropertyContainer

+ (instancetype)containerWithWeakProperty:(id)weakProperty {
    SAWeakPropertyContainer *container = [[SAWeakPropertyContainer alloc]init];
    container.weakProperty = weakProperty;
    return container;
}

@end
