//
// NSObject+SACellClick.m
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

#import "NSObject+DelegateProxy.h"
#import <objc/runtime.h>

@interface SADelegateProxyParasite : NSObject

@property (nonatomic, copy) void(^deallocBlock)(void);

@end

@implementation SADelegateProxyParasite

- (void)dealloc {
    !self.deallocBlock ?: self.deallocBlock();
}

@end

static void *const kSADelegateProxyParasiteName = (void *)&kSADelegateProxyParasiteName;
static void *const kSADelegateProxyClassName = (void *)&kSADelegateProxyClassName;
static void *const kSADelegateSelectors = (void *)&kSADelegateSelectors;
static void *const kSADelegateOptionalSelectors = (void *)&kSADelegateOptionalSelectors;
static void *const kSADelegateProxy = (void *)&kSADelegateProxy;

@interface NSObject (SACellClick)

@property (nonatomic, strong) SADelegateProxyParasite *sensorsdata_parasite;

@end

@implementation NSObject (DelegateProxy)

- (SADelegateProxyParasite *)sensorsdata_parasite {
    return objc_getAssociatedObject(self, kSADelegateProxyParasiteName);
}

- (void)setSensorsdata_parasite:(SADelegateProxyParasite *)parasite {
    objc_setAssociatedObject(self, kSADelegateProxyParasiteName, parasite, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)sensorsdata_className {
    return objc_getAssociatedObject(self, kSADelegateProxyClassName);
}

- (void)setSensorsdata_className:(NSString *)sensorsdata_className {
    objc_setAssociatedObject(self, kSADelegateProxyClassName, sensorsdata_className, OBJC_ASSOCIATION_COPY);
}

- (NSSet<NSString *> *)sensorsdata_selectors {
    return objc_getAssociatedObject(self, kSADelegateSelectors);
}

- (void)setSensorsdata_selectors:(NSSet<NSString *> *)sensorsdata_selectors {
    objc_setAssociatedObject(self, kSADelegateSelectors, sensorsdata_selectors, OBJC_ASSOCIATION_COPY);
}

- (NSSet<NSString *> *)sensorsdata_optionalSelectors {
    return objc_getAssociatedObject(self, kSADelegateOptionalSelectors);
}

- (void)setSensorsdata_optionalSelectors:(NSSet<NSString *> *)sensorsdata_optionalSelectors {
    objc_setAssociatedObject(self, kSADelegateOptionalSelectors, sensorsdata_optionalSelectors, OBJC_ASSOCIATION_COPY);
}

- (id)sensorsdata_delegateProxy {
    return objc_getAssociatedObject(self, kSADelegateProxy);
}

- (void)setSensorsdata_delegateProxy:(id)sensorsdata_delegateProxy {
    objc_setAssociatedObject(self, kSADelegateProxy, sensorsdata_delegateProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)sensorsdata_registerDeallocBlock:(void (^)(void))deallocBlock {
    if (!self.sensorsdata_parasite) {
        self.sensorsdata_parasite = [[SADelegateProxyParasite alloc] init];
        self.sensorsdata_parasite.deallocBlock = deallocBlock;
    }
}

- (BOOL)sensorsdata_respondsToSelector:(SEL)aSelector {
    if ([self sensorsdata_respondsToSelector:aSelector]) {
        return YES;
    }
    if ([self.sensorsdata_optionalSelectors containsObject:NSStringFromSelector(aSelector)]) {
        return YES;
    }
    return NO;
}

@end
