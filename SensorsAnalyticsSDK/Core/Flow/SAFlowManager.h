//
// SAFlowManager.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/2/17.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAConfigOptions.h"
#import "SAFlowObject.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSATrackFlowId;
extern NSString * const kSAFlushFlowId;
extern NSString * const kSATFlushFlowId;

@interface SAFlowManager : NSObject

@property (nonatomic, strong) SAConfigOptions *configOptions;

+ (instancetype)sharedInstance;

/// 加载 flow
///
/// 解析 json 配置创建 flow 并注册
- (void)loadFlows;

- (void)registerFlow:(SAFlowObject *)flow;
- (void)registerFlows:(NSArray<SAFlowObject *> *)flows;

- (SAFlowObject *)flowForID:(NSString *)flowID;

- (void)startWithFlowID:(NSString *)flowID input:(SAFlowData *)input completion:(nullable SAFlowDataCompletion)completion;
- (void)startWithFlow:(SAFlowObject *)flow input:(SAFlowData *)input completion:(nullable SAFlowDataCompletion)completion;

@end

NS_ASSUME_NONNULL_END
