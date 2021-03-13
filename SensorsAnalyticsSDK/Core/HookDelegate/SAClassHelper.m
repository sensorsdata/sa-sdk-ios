//
// SAClassHelper.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2020/11/5.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAClassHelper.h"
#import <objc/runtime.h>

@implementation SAClassHelper

+ (Class _Nullable)allocateClassWithObject:(id)object className:(NSString *)className {
    if (!object || className.length <= 0) {
        return nil;
    }
    Class originalClass = object_getClass(object);
    Class subclass = NSClassFromString(className);
    if (subclass) {
        return nil;
    }
    subclass = objc_allocateClassPair(originalClass, className.UTF8String, 0);
    if (class_getInstanceSize(originalClass) != class_getInstanceSize(subclass)) {
        return nil;
    }
    return subclass;
}

+ (void)registerClass:(Class)cla {
    if (cla) {
        objc_registerClassPair(cla);
    }
}

+ (BOOL)setObject:(id)object toClass:(Class)cla {
    if (cla && object) {
        return object_setClass(object, cla);
    }
    return NO;
}

+ (void)disposeClass:(Class)cla {
    if (cla) {
        objc_disposeClassPair(cla);
    }
}

+ (Class _Nullable)realClassWithObject:(id)object {
    return object_getClass(object);
}

+ (Class _Nullable)realSuperClassWithClass:(Class _Nullable)cla {
    return class_getSuperclass(cla);
}

@end
