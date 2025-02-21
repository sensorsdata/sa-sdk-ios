//
// SAInterceptor.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAInterceptor : NSObject

@property (nonatomic, strong) SAFlowData *input;
@property (nonatomic, strong) SAFlowData *output;

+ (instancetype)interceptorWithParam:(NSDictionary * _Nullable)param;

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion;

@end

NS_ASSUME_NONNULL_END
