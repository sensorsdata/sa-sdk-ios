//
// SASAFlushJSONInterceptor+Encrypt.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/4/7.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//


#import "SAFlushJSONInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAFlushJSONInterceptor (Encrypt)

- (NSString *)sensorsdata_buildJSONStringWithFlowData:(SAFlowData *)flowData;

@end

NS_ASSUME_NONNULL_END
