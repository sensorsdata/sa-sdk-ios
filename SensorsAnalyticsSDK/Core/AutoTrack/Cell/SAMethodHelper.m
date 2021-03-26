//
//  SAMethodHelper.m
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

#import "SAMethodHelper.h"
#import <objc/runtime.h>
#import "SALog.h"

@implementation SAMethodHelper

+ (IMP)implementationOfMethodSelector:(SEL)selector fromClass:(Class)aClass {
    // 获取一个实例方法的指针
    Method aMethod = class_getInstanceMethod(aClass, selector);
    // 返回该方法的实现
    return method_getImplementation(aMethod);
}

+ (void)addInstanceMethodWithSelector:(SEL)methodSelector fromClass:(Class)fromClass toClass:(Class)toClass {
    [self addInstanceMethodWithDestinationSelector:methodSelector sourceSelector:methodSelector fromClass:fromClass toClass:toClass];
}

+ (void)addInstanceMethodWithDestinationSelector:(SEL)destinationSelector sourceSelector:(SEL)sourceSelector fromClass:(Class)fromClass toClass:(Class)toClass {
    // 获取一个实例方法的指针
    Method method = class_getInstanceMethod(fromClass, sourceSelector);
    // 返回该方法的实现
    IMP methodIMP = method_getImplementation(method);
    // 获取该方法的返回类型
    const char *types = method_getTypeEncoding(method);
    // 在 toClass 中，添加一个名为 destinationSelector 的方法
    if (!class_addMethod(toClass, destinationSelector, methodIMP, types)) {
        class_replaceMethod(toClass, destinationSelector, methodIMP, types);
    }
}

+ (void)addClassMethodWithDestinationSelector:(SEL)destinationSelector sourceSelector:(SEL)sourceSelector fromClass:(Class)fromClass toClass:(Class)toClass {
    Method method = class_getClassMethod(fromClass, sourceSelector);
    IMP methodIMP = method_getImplementation(method);
    const char *types = method_getTypeEncoding(method);
    if (!class_addMethod(toClass, destinationSelector, methodIMP, types)) {
        class_replaceMethod(toClass, destinationSelector, methodIMP, types);
    }
}

+ (IMP _Nullable)replaceInstanceMethodWithDestinationSelector:(SEL)destinationSelector sourceSelector:(SEL)sourceSelector fromClass:(Class)fromClass toClass:(Class)toClass {
    Method method = class_getInstanceMethod(fromClass, sourceSelector);
    IMP methodIMP = method_getImplementation(method);
    const char *types = method_getTypeEncoding(method);
    return class_replaceMethod(toClass, destinationSelector, methodIMP, types);
}

@end
