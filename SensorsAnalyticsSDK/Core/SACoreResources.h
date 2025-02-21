//
// SACoreResources.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2023/1/16.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SACoreResources : NSObject

+ (NSArray *)analyticsFlows;

+ (NSArray *)analyticsTasks;

+ (NSArray *)analyticsNodes;

/// 默认加载中文资源
+ (NSDictionary *)defaultLanguageResources;

@end

NS_ASSUME_NONNULL_END
