//
// SAFlowManager.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/2/17.
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

#import <Foundation/Foundation.h>
#import "SAConfigOptions.h"
#import "SAFlowObject.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSATrackFlowId;
extern NSString * const kSAFlushFlowId;

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
- (void)startWithFlow:(SAFlowObject *)flow input:(SAFlowData *)input completion:(SAFlowDataCompletion)completion;

@end

NS_ASSUME_NONNULL_END
