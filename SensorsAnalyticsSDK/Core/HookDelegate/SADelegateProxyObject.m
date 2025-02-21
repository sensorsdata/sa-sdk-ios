//
// SADelegateProxyObject.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/11/12.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SADelegateProxyObject.h"
#import <objc/message.h>

NSString * const kSADelegateClassSensorsSuffix = @"_CN.SENSORSDATA";
NSString * const kSADelegateClassKVOPrefix = @"KVONotifying_";

@implementation SADelegateProxyObject

- (instancetype)initWithDelegate:(id)delegate proxy:(id)proxy {
    self = [super init];
    if (self) {
        _delegateProxy = proxy;

        _selectors = [NSMutableSet set];
        _delegateClass = [delegate class];

        Class cla = object_getClass(delegate);
        NSString *name = NSStringFromClass(cla);

        if ([name containsString:kSADelegateClassKVOPrefix]) {
            _delegateISA = class_getSuperclass(cla);
            _kvoClass = cla;
        } else if ([name containsString:kSADelegateClassSensorsSuffix]) {
            _delegateISA = class_getSuperclass(cla);
            _sensorsClassName = name;
        } else {
            _delegateISA = cla;
            _sensorsClassName = [NSString stringWithFormat:@"%@%@", name, kSADelegateClassSensorsSuffix];
        }
    }
    return self;
}

- (Class)sensorsClass {
    return NSClassFromString(self.sensorsClassName);
}

- (void)removeKVO {
    self.kvoClass = nil;
    self.sensorsClassName = [NSString stringWithFormat:@"%@%@", self.delegateISA, kSADelegateClassSensorsSuffix];
    [self.selectors removeAllObjects];
}

@end

#pragma mark - Utils

@implementation SADelegateProxyObject (Utils)

/// 是不是 KVO 创建的类
/// @param cls 类
+ (BOOL)isKVOClass:(Class _Nullable)cls {
    return [NSStringFromClass(cls) containsString:kSADelegateClassKVOPrefix];
}

@end

