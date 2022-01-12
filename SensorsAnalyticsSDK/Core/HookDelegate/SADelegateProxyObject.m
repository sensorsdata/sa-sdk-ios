//
// SADelegateProxyObject.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/11/12.
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

