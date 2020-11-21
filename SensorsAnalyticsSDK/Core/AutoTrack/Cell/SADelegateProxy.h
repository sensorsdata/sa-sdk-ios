//
//  SADelegateProxy.m
//  SensorsAnalyticsSDK
//
//  Created by 张敏超🍎 on 2019/6/19.
//  Copyright © 2019 SensorsData. All rights reserved.
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

NS_ASSUME_NONNULL_BEGIN

@interface SADelegateProxy : NSObject

/**
 对 TableView 和 CollectionView 的单元格选中方法进行代理

 @param delegate 代理：UITableViewDelegate、UICollectionViewDelegate 等
 */
+ (void)proxyWithDelegate:(id)delegate;

@end

@interface SADelegateProxy (ThirdPart)

+ (BOOL)isRxDelegateProxyClass:(Class)cla;

@end

@interface SADelegateProxy (Utils)

+ (BOOL)isKVOClass:(Class _Nullable)cls;

+ (BOOL)isSensorsClass:(Class _Nullable)cls;

+ (NSString *)generateSensorsClassName:(id)obj;

+ (Class _Nullable)sensorsClassInInheritanceChain:(id _Nullable)obj;

@end

NS_ASSUME_NONNULL_END
