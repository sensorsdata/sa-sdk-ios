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

static void *const kSANSObjectDelegateProxyParasiteKey = (void *)&kSANSObjectDelegateProxyParasiteKey;
static void *const kSANSObjectDelegateProxyClassNameKey = (void *)&kSANSObjectDelegateProxyClassNameKey;
static void *const kSANSObjectDelegateSelectorsKey = (void *)&kSANSObjectDelegateSelectorsKey;
static void *const kSANSObjectDelegateOptionalSelectorsKey = (void *)&kSANSObjectDelegateOptionalSelectorsKey;
static void *const kSANSObjectDelegateProxyKey = (void *)&kSANSObjectDelegateProxyKey;

static void *const kSANSProxyDelegateProxyParasiteKey = (void *)&kSANSProxyDelegateProxyParasiteKey;
static void *const kSANSProxyDelegateProxyClassNameKey = (void *)&kSANSProxyDelegateProxyClassNameKey;
static void *const kSANSProxyDelegateSelectorsKey = (void *)&kSANSProxyDelegateSelectorsKey;
static void *const kSANSProxyDelegateOptionalSelectorsKey = (void *)&kSANSProxyDelegateOptionalSelectorsKey;
static void *const kSANSProxyDelegateProxyKey = (void *)&kSANSProxyDelegateProxyKey;

@implementation SADelegateProxyParasite

- (void)dealloc {
    !self.deallocBlock ?: self.deallocBlock();
}

@end

@implementation NSObject (DelegateProxy)

- (SADelegateProxyParasite *)sensorsdata_parasite {
    return objc_getAssociatedObject(self, kSANSObjectDelegateProxyParasiteKey);
}

- (void)setSensorsdata_parasite:(SADelegateProxyParasite *)sensorsdata_parasite {
    objc_setAssociatedObject(self, kSANSObjectDelegateProxyParasiteKey, sensorsdata_parasite, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)sensorsdata_className {
    return objc_getAssociatedObject(self, kSANSObjectDelegateProxyClassNameKey);
}

- (void)setSensorsdata_className:(NSString *)sensorsdata_className {
    objc_setAssociatedObject(self, kSANSObjectDelegateProxyClassNameKey, sensorsdata_className, OBJC_ASSOCIATION_COPY);
}

- (NSSet<NSString *> *)sensorsdata_selectors {
    return objc_getAssociatedObject(self, kSANSObjectDelegateSelectorsKey);
}

- (void)setSensorsdata_selectors:(NSSet<NSString *> *)sensorsdata_selectors {
    objc_setAssociatedObject(self, kSANSObjectDelegateSelectorsKey, sensorsdata_selectors, OBJC_ASSOCIATION_COPY);
}

- (NSSet<NSString *> *)sensorsdata_optionalSelectors {
    return objc_getAssociatedObject(self, kSANSObjectDelegateOptionalSelectorsKey);
}

- (void)setSensorsdata_optionalSelectors:(NSSet<NSString *> *)sensorsdata_optionalSelectors {
    objc_setAssociatedObject(self, kSANSObjectDelegateOptionalSelectorsKey, sensorsdata_optionalSelectors, OBJC_ASSOCIATION_COPY);
}

- (id)sensorsdata_delegateProxy {
    return objc_getAssociatedObject(self, kSANSObjectDelegateProxyKey);
}

- (void)setSensorsdata_delegateProxy:(id)sensorsdata_delegateProxy {
    objc_setAssociatedObject(self, kSANSObjectDelegateProxyKey, sensorsdata_delegateProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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


@implementation NSProxy (DelegateProxy)

- (SADelegateProxyParasite *)sensorsdata_parasite {
    return objc_getAssociatedObject(self, kSANSProxyDelegateProxyParasiteKey);
}

- (void)setSensorsdata_parasite:(SADelegateProxyParasite *)sensorsdata_parasite {
    objc_setAssociatedObject(self, kSANSProxyDelegateProxyParasiteKey, sensorsdata_parasite, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)sensorsdata_className {
    return objc_getAssociatedObject(self, kSANSProxyDelegateProxyClassNameKey);
}

- (void)setSensorsdata_className:(NSString *)sensorsdata_className {
    objc_setAssociatedObject(self, kSANSProxyDelegateProxyClassNameKey, sensorsdata_className, OBJC_ASSOCIATION_COPY);
}

- (NSSet<NSString *> *)sensorsdata_selectors {
    return objc_getAssociatedObject(self, kSANSProxyDelegateSelectorsKey);
}

- (void)setSensorsdata_selectors:(NSSet<NSString *> *)sensorsdata_selectors {
    objc_setAssociatedObject(self, kSANSProxyDelegateSelectorsKey, sensorsdata_selectors, OBJC_ASSOCIATION_COPY);
}

- (NSSet<NSString *> *)sensorsdata_optionalSelectors {
    return objc_getAssociatedObject(self, kSANSProxyDelegateOptionalSelectorsKey);
}

- (void)setSensorsdata_optionalSelectors:(NSSet<NSString *> *)sensorsdata_optionalSelectors {
    objc_setAssociatedObject(self, kSANSProxyDelegateOptionalSelectorsKey, sensorsdata_optionalSelectors, OBJC_ASSOCIATION_COPY);
}

- (id)sensorsdata_delegateProxy {
    return objc_getAssociatedObject(self, kSANSProxyDelegateProxyKey);
}

- (void)setSensorsdata_delegateProxy:(id)sensorsdata_delegateProxy {
    objc_setAssociatedObject(self, kSANSProxyDelegateProxyKey, sensorsdata_delegateProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
