//
// SAAutoTrackResources.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2023/1/16.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAAutoTrackResources : NSObject

+ (NSDictionary *)gestureViewBlacklist;

+ (NSDictionary *)viewControllerBlacklist;

@end

NS_ASSUME_NONNULL_END
