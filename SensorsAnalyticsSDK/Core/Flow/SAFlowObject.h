//
// SAFlowObject.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SATaskObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAFlowObject : NSObject

@property (nonatomic, copy) NSString *flowID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSArray<NSString *> *taskIDs;
@property (nonatomic, strong) NSArray<SATaskObject *> *tasks;
@property (nonatomic, strong) NSDictionary<NSString *, id> *param;

- (instancetype)initWithFlowID:(NSString *)flowID name:(NSString *)name tasks:(NSArray<SATaskObject *> *)tasks;
- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dic;

- (nullable SATaskObject *)taskForID:(NSString *)taskID;

+ (NSDictionary<NSString *, SAFlowObject *> *)loadFromBundle:(NSBundle *)bundle;
+ (NSDictionary<NSString *, SAFlowObject *> *)loadFromResources:(NSArray *)array;

@end

NS_ASSUME_NONNULL_END
