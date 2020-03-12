//
//  SAApplicationStateSerializer.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>

@class SAObjectSerializerConfig;
@class SAObjectIdentityProvider;

@interface SAApplicationStateSerializer : NSObject

- (instancetype)initWithApplication:(UIApplication *)application
                      configuration:(SAObjectSerializerConfig *)configuration
             objectIdentityProvider:(SAObjectIdentityProvider *)objectIdentityProvider;


/// keyWindow 截图
- (UIImage *)screenshotImageForKeyWindow;

/// 所有 window 截图合成
- (void)screenshotImageForAllWindowWithCompletionHandler:(void(^)(UIImage *))completionHandler;

- (NSDictionary *)objectHierarchyForWindow:(UIWindow *)window;

@end
