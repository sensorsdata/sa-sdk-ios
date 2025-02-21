//
// SAApplicationStateSerializer.h
// SensorsAnalyticsSDK
//
// Created by 雨晗 on 1/18/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SAObjectSerializerConfig;
@class SAObjectIdentityProvider;

@interface SAApplicationStateSerializer : NSObject

- (instancetype)initWithConfiguration:(SAObjectSerializerConfig *)configuration
             objectIdentityProvider:(SAObjectIdentityProvider *)objectIdentityProvider;

/// 所有 window 截图合成
- (void)screenshotImageForAllWindowWithCompletionHandler:(void(^)(UIImage *))completionHandler;

- (NSDictionary *)objectHierarchyForRootObject;

@end
