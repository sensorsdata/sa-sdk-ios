//
// SAFlushJSONInterceptor.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

// 多条埋点数据拼接组装
@interface SAFlushJSONInterceptor : SAInterceptor

- (NSString *)buildJSONStringWithFlowData:(SAFlowData *)flowData;

@end

NS_ASSUME_NONNULL_END
