//
// SensorsAnalyticsSDK+SAAppExtension.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/5/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SensorsAnalyticsSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK (SAAppExtension)

/**
 @abstract
 * Track App Extension groupIdentifier 中缓存的数据
 *
 * @param groupIdentifier groupIdentifier
 * @param completion  完成 track 后的 callback
 */
- (void)trackEventFromExtensionWithGroupIdentifier:(NSString *)groupIdentifier completion:(void (^)(NSString *groupIdentifier, NSArray *events)) completion;

@end

NS_ASSUME_NONNULL_END
