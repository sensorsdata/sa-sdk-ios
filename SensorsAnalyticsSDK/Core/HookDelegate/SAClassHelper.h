//
// SAClassHelper.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2020/11/5.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAClassHelper : NSObject

/// 动态创建 Class, 类名为 className, 父类为 delegate 的当前类
/// @param object 实例对象
/// @param className 类名
+ (Class _Nullable)allocateClassWithObject:(id)object className:(NSString *)className;

/// 动态创建类后, 注册类
/// @param cla 待注册的类
+ (void)registerClass:(Class)cla;

/// 把实例对象的类变更为另外的类
/// @param object 实例对象
/// @param cla 要变更的目标类
+ (BOOL)setObject:(id)object toClass:(Class)cla;

@end

NS_ASSUME_NONNULL_END
