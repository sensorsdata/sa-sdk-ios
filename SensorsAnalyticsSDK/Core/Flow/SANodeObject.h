//
// SANodeObject.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAInterceptor.h"
#import "SAFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@interface SANodeObject : NSObject

@property (nonatomic, copy) NSString *nodeID;
@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *interceptorClassName;
@property (nonatomic, strong) NSDictionary<NSString *, id> *param;

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dic;
- (instancetype)initWithNodeID:(NSString *)nodeID name:(NSString *)name interceptor:(SAInterceptor *)interceptor;

@property (nonatomic, strong, readonly) SAInterceptor *interceptor;

+ (NSDictionary<NSString *, SANodeObject *> *)loadFromBundle:(NSBundle *)bundle;
+ (NSDictionary<NSString *, SANodeObject *> *)loadFromResources:(NSArray *)array;

@end

NS_ASSUME_NONNULL_END
