//
//  SAApplicationStateSerializer.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SAObjectSerializerConfig;
@class SAObjectIdentityProvider;

@interface SAApplicationStateSerializer : NSObject

- (instancetype)initWithApplication:(UIApplication *)application
                      configuration:(SAObjectSerializerConfig *)configuration
             objectIdentityProvider:(SAObjectIdentityProvider *)objectIdentityProvider;

- (UIImage *)screenshotImageForWindow:(UIWindow *)window;

- (NSDictionary *)objectHierarchyForWindow:(UIWindow *)window;

@end