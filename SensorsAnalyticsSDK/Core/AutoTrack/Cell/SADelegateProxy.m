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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SADelegateProxy.h"
#import "SAClassHelper.h"
#import "SAMethodHelper.h"
#import "NSObject+SACellClick.h"
#import "SALog.h"
#import "SAAutoTrackUtils.h"
#import "SAAutoTrackProperty.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import <objc/message.h>

typedef void (*SensorsDidSelectImplementation)(id, SEL, UIScrollView *, NSIndexPath *);

@implementation SADelegateProxy

+ (void)proxyWithDelegate:(id)delegate {
    @try {
        [SADelegateProxy hookDidSelectMethodWithDelegate:delegate];
    } @catch (NSException *exception) {
        return SALogError(@"%@", exception);
    }
}

+ (void)hookDidSelectMethodWithDelegate:(id)delegate {
    // 当前代理对象已经处理过
    if ([delegate sensorsdata_className]) {
        return;
    }
    
    SEL tablViewSelector = @selector(tableView:didSelectRowAtIndexPath:);
    SEL collectionViewSelector = @selector(collectionView:didSelectItemAtIndexPath:);
    
    BOOL canResponseTableView = [delegate respondsToSelector:tablViewSelector];
    BOOL canResponseCollectionView = [delegate respondsToSelector:collectionViewSelector];
    
    // 代理对象未实现单元格选中方法, 则不处理
    if (!canResponseTableView && !canResponseCollectionView) {
        return;
    }
    Class proxyClass = [SADelegateProxy class];
    // KVO 创建子类后会重写 - (Class)class 方法, 直接通过 object.class 无法获取真实的类
    Class realClass = [SAClassHelper realClassWithObject:delegate];
    // 如果当前代理对象归属为 KVO 创建的类, 则无需新建子类
    if ([SADelegateProxy isKVOClass:realClass]) {
        // 记录 KVO 的父类(KVO 会重写 class 方法, 返回父类)
        [delegate setSensorsdata_className:NSStringFromClass([delegate class])];
        if ([realClass isKindOfClass:[NSObject class]]) {
            // 在移除所有的 KVO 属性监听时, 系统会重置对象的 isa 指针为原有的类; 因此需要在移除监听时, 重新为代理对象设置新的子类, 来采集点击事件
            [SAMethodHelper addInstanceMethodWithSelector:@selector(removeObserver:forKeyPath:) fromClass:proxyClass toClass:realClass];
        }
        
        // 给 KVO 的类添加 cell 点击方法, 采集点击事件
        [SAMethodHelper addInstanceMethodWithSelector:tablViewSelector fromClass:proxyClass toClass:realClass];
        [SAMethodHelper addInstanceMethodWithSelector:collectionViewSelector fromClass:proxyClass toClass:realClass];
        return;
    }
    
    // 创建类
    NSString *dynamicClassName = [SADelegateProxy generateSensorsClassName:delegate];
    Class dynamicClass = [SAClassHelper allocateClassWithObject:delegate className:dynamicClassName];
    if (!dynamicClass) {
        return;
    }
    
    // 给新创建的类添加 cell 点击方法, 采集点击事件
    [SAMethodHelper addInstanceMethodWithSelector:tablViewSelector fromClass:proxyClass toClass:dynamicClass];
    [SAMethodHelper addInstanceMethodWithSelector:collectionViewSelector fromClass:proxyClass toClass:dynamicClass];

    if ([realClass isKindOfClass:[NSObject class]]) {
        // 新建子类后,需要监听是否添加了 KVO, 因为添加 KVO 属性监听后, KVO 会重写 Class 方法, 导致获取的 Class 为神策添加的子类
        [SAMethodHelper addInstanceMethodWithSelector:@selector(addObserver:forKeyPath:options:context:) fromClass:proxyClass toClass:dynamicClass];
    }
    
    // 记录对象的原始类名 (因为 class 方法需要使用, 所以在重写 class 方法前设置)
    [delegate setSensorsdata_className:NSStringFromClass(realClass)];
    // 重写 - (Class)class 方法，隐藏新添加的子类
    [SAMethodHelper addInstanceMethodWithSelector:@selector(class) fromClass:proxyClass toClass:dynamicClass];
    
    // 使类生效
    [SAClassHelper registerClass:dynamicClass];
    
    // 替换代理对象所归属的类
    if ([SAClassHelper setObject:delegate toClass:dynamicClass]) {
        // 在对象释放时, 释放创建的子类
        [delegate sensorsdata_registerDeallocBlock:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [SAClassHelper disposeClass:dynamicClass];
            });
        }];
    }
}

@end

#pragma mark - UITableViewDelegate & UICollectionViewDelegate

@implementation SADelegateProxy (SubclassMethod)

/// Overridden instance class method
- (Class)class {
    if (self.sensorsdata_className) {
        return NSClassFromString(self.sensorsdata_className);
    }
    return [super class];
}

+ (void)invokeWithTarget:(NSObject *)target selector:(SEL)selector scrollView:(UIScrollView *)scrollView indexPath:(NSIndexPath *)indexPath {
    Class originalClass = NSClassFromString(target.sensorsdata_className) ?: target.superclass;
    struct objc_super targetSuper = {
        .receiver = target,
        .super_class = originalClass
    };
    // 消息转发给原始类
    void (*func)(struct objc_super *, SEL, id, id) = (void *)&objc_msgSendSuper;
    func(&targetSuper, selector, scrollView, indexPath);
    
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != scrollView.delegate) {
        return;
    }

    NSMutableDictionary *properties = [SAAutoTrackUtils propertiesWithAutoTrackObject:(UIScrollView<SAAutoTrackViewProperty> *)scrollView didSelectedAtIndexPath:indexPath];
    if (!properties) {
        return;
    }
    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackDelegate:scrollView didSelectedAtIndexPath:indexPath];
    [properties addEntriesFromDictionary:dic];

    [[SensorsAnalyticsSDK sharedInstance] trackAutoEvent:SA_EVENT_NAME_APP_CLICK properties:properties];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SEL methodSelector = @selector(tableView:didSelectRowAtIndexPath:);
    [SADelegateProxy invokeWithTarget:self selector:methodSelector scrollView:tableView indexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    SEL methodSelector = @selector(collectionView:didSelectItemAtIndexPath:);
    [SADelegateProxy invokeWithTarget:self selector:methodSelector scrollView:collectionView indexPath:indexPath];
}

@end

#pragma mark - KVO
@implementation SADelegateProxy (KVO)

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
    if (self.sensorsdata_className) {
        // 由于添加了 KVO 属性监听, KVO 会创建子类并重写 Class 方法,返回原始类; 此时的原始类为神策添加的子类,因此需要重写 class 方法
        [SAMethodHelper replaceInstanceMethodWithDestinationSelector:@selector(class) sourceSelector:@selector(class) fromClass:SADelegateProxy.class toClass:[SAClassHelper realClassWithObject:self]];
    }
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    // remove 前代理对象是否归属于 KVO 创建的类
    BOOL oldClassIsKVO = [SADelegateProxy isKVOClass:[SAClassHelper realClassWithObject:self]];
    [super removeObserver:observer forKeyPath:keyPath];
    // remove 后代理对象是否归属于 KVO 创建的类
    BOOL newClassIsKVO = [SADelegateProxy isKVOClass:[SAClassHelper realClassWithObject:self]];
    
    // 有多个属性监听时, 在最后一个监听被移除后, 对象的 isa 发生变化, 需要重新为代理对象添加子类
    if (oldClassIsKVO && !newClassIsKVO) {
        // 清空已经记录的原始类
        self.sensorsdata_className = nil;
        [SADelegateProxy proxyWithDelegate:self];
    }
}

@end

#pragma mark - Utils
/// Delegate 的类前缀
static NSString *const kSADelegateSuffix = @"__CN.SENSORSDATA";
static NSString *const kSAKVODelegatePrefix = @"KVONotifying_";
static NSString *const kSAClassSeparatedChar = @".";
static long subClassIndex = 0;

@implementation SADelegateProxy (Utils)

/// 是不是 KVO 创建的类
/// @param cls 类
+ (BOOL)isKVOClass:(Class _Nullable)cls {
    return [NSStringFromClass(cls) containsString:kSAKVODelegatePrefix];
}

/// 是不是神策创建的类
/// @param cls 类
+ (BOOL)isSensorsClass:(Class _Nullable)cls {
    return [NSStringFromClass(cls) containsString:kSADelegateSuffix];
}

/// 生成神策要创建类的类名
/// @param obj 实例对象
+ (NSString *)generateSensorsClassName:(id)obj {
    Class class = [SAClassHelper realClassWithObject:obj];
    if ([SADelegateProxy isSensorsClass:class]) return NSStringFromClass(class);
    return [NSString stringWithFormat:@"%@%@%@%@", NSStringFromClass(class), kSAClassSeparatedChar, @(subClassIndex++), kSADelegateSuffix];
}

@end
