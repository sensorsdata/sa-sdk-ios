//
// NSObject+SADelegateProxy.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2020/11/5.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SADelegateProxyObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (DelegateProxy)

@property (nonatomic, copy, nullable) NSSet<NSString *> *sensorsdata_optionalSelectors;
@property (nonatomic, strong, nullable) SADelegateProxyObject *sensorsdata_delegateObject;

/// hook respondsToSelector to resolve optional selectors
/// @param aSelector selector
- (BOOL)sensorsdata_respondsToSelector:(SEL)aSelector;

@end

@interface NSProxy (DelegateProxy)

@property (nonatomic, copy, nullable) NSSet<NSString *> *sensorsdata_optionalSelectors;
@property (nonatomic, strong, nullable) SADelegateProxyObject *sensorsdata_delegateObject;

/// hook respondsToSelector to resolve optional selectors
/// @param aSelector selector
- (BOOL)sensorsdata_respondsToSelector:(SEL)aSelector;

@end

NS_ASSUME_NONNULL_END
