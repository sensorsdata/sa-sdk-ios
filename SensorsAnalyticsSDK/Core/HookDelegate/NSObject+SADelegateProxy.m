//
// NSObject+SACellClick.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2020/11/5.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "NSObject+SADelegateProxy.h"
#import <objc/runtime.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

static void *const kSANSObjectDelegateOptionalSelectorsKey = (void *)&kSANSObjectDelegateOptionalSelectorsKey;
static void *const kSANSObjectDelegateObjectKey = (void *)&kSANSObjectDelegateObjectKey;

static void *const kSANSProxyDelegateOptionalSelectorsKey = (void *)&kSANSProxyDelegateOptionalSelectorsKey;
static void *const kSANSProxyDelegateObjectKey = (void *)&kSANSProxyDelegateObjectKey;

@implementation NSObject (DelegateProxy)

- (NSSet<NSString *> *)sensorsdata_optionalSelectors {
    return objc_getAssociatedObject(self, kSANSObjectDelegateOptionalSelectorsKey);
}

- (void)setSensorsdata_optionalSelectors:(NSSet<NSString *> *)sensorsdata_optionalSelectors {
    objc_setAssociatedObject(self, kSANSObjectDelegateOptionalSelectorsKey, sensorsdata_optionalSelectors, OBJC_ASSOCIATION_COPY);
}

- (SADelegateProxyObject *)sensorsdata_delegateObject {
    return objc_getAssociatedObject(self, kSANSObjectDelegateObjectKey);
}

- (void)setSensorsdata_delegateObject:(SADelegateProxyObject *)sensorsdata_delegateObject {
    objc_setAssociatedObject(self, kSANSObjectDelegateObjectKey, sensorsdata_delegateObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sensorsdata_respondsToSelector:(SEL)aSelector {
    if ([self sensorsdata_respondsToSelector:aSelector]) {
        return YES;
    }

#if TARGET_OS_IOS
    if (@available(iOS 18.0, *)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpointer-to-int-cast"
        char cString = (char)sel_getName(aSelector);
#pragma clang diagnostic pop
        if (cString == '\x01') {
            return NO;
        }
    }
#endif

    if ([self.sensorsdata_optionalSelectors containsObject:NSStringFromSelector(aSelector)]) {
        return YES;
    }
    return NO;
}

@end

@implementation NSProxy (DelegateProxy)

- (NSSet<NSString *> *)sensorsdata_optionalSelectors {
    return objc_getAssociatedObject(self, kSANSProxyDelegateOptionalSelectorsKey);
}

- (void)setSensorsdata_optionalSelectors:(NSSet<NSString *> *)sensorsdata_optionalSelectors {
    objc_setAssociatedObject(self, kSANSProxyDelegateOptionalSelectorsKey, sensorsdata_optionalSelectors, OBJC_ASSOCIATION_COPY);
}

- (SADelegateProxyObject *)sensorsdata_delegateObject {
    return objc_getAssociatedObject(self, kSANSProxyDelegateObjectKey);
}

- (void)setSensorsdata_delegateObject:(SADelegateProxyObject *)sensorsdata_delegateObject {
    objc_setAssociatedObject(self, kSANSProxyDelegateObjectKey, sensorsdata_delegateObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
