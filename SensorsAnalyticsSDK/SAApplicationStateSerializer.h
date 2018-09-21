//
//  SAApplicationStateSerializer.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
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
