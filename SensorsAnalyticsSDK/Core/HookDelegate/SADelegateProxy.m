//
// SADelegateProxy.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2019/6/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SADelegateProxy.h"
#import "SAClassHelper.h"
#import "SAMethodHelper.h"
#import "SALog.h"
#import "NSObject+DelegateProxy.h"
#import <objc/message.h>

static NSString * const kSANSObjectRemoveObserverSelector = @"removeObserver:forKeyPath:";
static NSString * const kSANSObjectAddObserverSelector = @"addObserver:forKeyPath:options:context:";
static NSString * const kSANSObjectClassSelector = @"class";

@implementation SADelegateProxy

+ (void)proxyDelegate:(id)delegate selectors:(NSSet<NSString *> *)selectors {
    if (object_isClass(delegate) || selectors.count == 0) {
        return;
    }

    Class proxyClass = [self class];
    NSMutableSet *delegateSelectors = [NSMutableSet setWithSet:selectors];

    SADelegateProxyObject *object = [delegate sensorsdata_delegateObject];
    if (!object) {
        object = [[SADelegateProxyObject alloc] initWithDelegate:delegate proxy:proxyClass];
        [delegate setSensorsdata_delegateObject:object];
    }

    [delegateSelectors minusSet:object.selectors];
    if (delegateSelectors.count == 0) {
        return;
    }

    if (object.sensorsClass) {
        [self addInstanceMethodWithSelectors:delegateSelectors fromClass:proxyClass toClass:object.sensorsClass];
        [object.selectors unionSet:delegateSelectors];

        // 代理对象未继承自神策类, 需要重置代理对象的 isa 为神策类
        if (![object_getClass(delegate) isSubclassOfClass:object.sensorsClass]) {
            [SAClassHelper setObject:delegate toClass:object.sensorsClass];
        }
        return;
    }

    if (object.kvoClass) {
        // 在移除所有的 KVO 属性监听时, 系统会重置对象的 isa 指针为原有的类;
        // 因此需要在移除监听时, 重新为代理对象设置新的子类, 来采集点击事件.
        if ([delegate isKindOfClass:NSObject.class] && ![object.selectors containsObject:kSANSObjectRemoveObserverSelector]) {
            [delegateSelectors addObject:kSANSObjectRemoveObserverSelector];
        }
        [self addInstanceMethodWithSelectors:delegateSelectors fromClass:proxyClass toClass:object.kvoClass];
        [object.selectors unionSet:delegateSelectors];
        return;
    }

    Class sensorsClass = [SAClassHelper allocateClassWithObject:delegate className:object.sensorsClassName];
    [SAClassHelper registerClass:sensorsClass];

    // 新建子类后, 需要监听是否添加了 KVO, 因为添加 KVO 属性监听后,
    // KVO 会重写 Class 方法, 导致获取的 Class 为神策添加的子类
    if ([delegate isKindOfClass:NSObject.class] && ![object.selectors containsObject:kSANSObjectAddObserverSelector]) {
        [delegateSelectors addObject:kSANSObjectAddObserverSelector];
    }

    // 重写 Class 方法
    if (![object.selectors containsObject:kSANSObjectClassSelector]) {
        [delegateSelectors addObject:kSANSObjectClassSelector];
    }

    [self addInstanceMethodWithSelectors:delegateSelectors fromClass:proxyClass toClass:sensorsClass];
    [object.selectors unionSet:delegateSelectors];

    [SAClassHelper setObject:delegate toClass:sensorsClass];
}

+ (void)addInstanceMethodWithSelectors:(NSSet<NSString *> *)selectors fromClass:(Class)fromClass toClass:(Class)toClass {
    for (NSString *selector in selectors) {
        SEL sel = NSSelectorFromString(selector);
        [SAMethodHelper addInstanceMethodWithSelector:sel fromClass:fromClass toClass:toClass];
    }
}

+ (void)invokeWithTarget:(NSObject *)target selector:(SEL)selector, ... {
    Class originalClass = target.sensorsdata_delegateObject.delegateISA;

    va_list args;
    va_start(args, selector);
    id arg1 = nil, arg2 = nil, arg3 = nil, arg4 = nil;
    NSInteger count = [NSStringFromSelector(selector) componentsSeparatedByString:@":"].count - 1;
    for (NSInteger i = 0; i < count; i++) {
        i == 0 ? (arg1 = va_arg(args, id)) : nil;
        i == 1 ? (arg2 = va_arg(args, id)) : nil;
        i == 2 ? (arg3 = va_arg(args, id)) : nil;
        i == 3 ? (arg4 = va_arg(args, id)) : nil;
    }
    struct objc_super targetSuper = {
        .receiver = target,
        .super_class = originalClass
    };
    // 消息转发给原始类
    @try {
        void (*func)(struct objc_super *, SEL, id, id, id, id) = (void *)&objc_msgSendSuper;
        func(&targetSuper, selector, arg1, arg2, arg3, arg4);
    } @catch (NSException *exception) {
        SALogInfo(@"msgSendSuper with exception: %@", exception);
    } @finally {
        va_end(args);
    }
}

+ (void)resolveOptionalSelectorsForDelegate:(id)delegate {
    if (object_isClass(delegate)) {
        return;
    }

    NSSet *currentOptionalSelectors = ((NSObject *)delegate).sensorsdata_optionalSelectors;
    NSMutableSet *optionalSelectors = [[NSMutableSet alloc] init];
    if (currentOptionalSelectors) {
        [optionalSelectors unionSet:currentOptionalSelectors];
    }
    
    if ([self respondsToSelector:@selector(optionalSelectors)] &&[self optionalSelectors]) {
        [optionalSelectors unionSet:[self optionalSelectors]];
    }
    ((NSObject *)delegate).sensorsdata_optionalSelectors = [optionalSelectors copy];
}

@end

#pragma mark - Class
@implementation SADelegateProxy (Class)

- (Class)class {
    if (self.sensorsdata_delegateObject.delegateClass) {
        return self.sensorsdata_delegateObject.delegateClass;
    }
    return [super class];
}

@end

#pragma mark - KVO
@implementation SADelegateProxy (KVO)

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
    if (self.sensorsdata_delegateObject) {
        // 由于添加了 KVO 属性监听, KVO 会创建子类并重写 Class 方法,返回原始类; 此时的原始类为神策添加的子类,因此需要重写 class 方法
        [SAMethodHelper replaceInstanceMethodWithDestinationSelector:@selector(class) sourceSelector:@selector(class) fromClass:SADelegateProxy.class toClass:object_getClass(self)];
    }
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    // remove 前代理对象是否归属于 KVO 创建的类
    BOOL oldClassIsKVO = [SADelegateProxyObject isKVOClass:object_getClass(self)];
    [super removeObserver:observer forKeyPath:keyPath];
    // remove 后代理对象是否归属于 KVO 创建的类
    BOOL newClassIsKVO = [SADelegateProxyObject isKVOClass:object_getClass(self)];
    
    // 有多个属性监听时, 在最后一个监听被移除后, 对象的 isa 发生变化, 需要重新为代理对象添加子类
    if (oldClassIsKVO && !newClassIsKVO) {
        Class delegateProxy = self.sensorsdata_delegateObject.delegateProxy;
        NSSet *selectors = [self.sensorsdata_delegateObject.selectors copy];

        [self.sensorsdata_delegateObject removeKVO];
        if ([delegateProxy respondsToSelector:@selector(proxyDelegate:selectors:)]) {
            [delegateProxy proxyDelegate:self selectors:selectors];
        }
    }
}

@end
