//
// SAFlushHTTPBodyInterceptor+Encrypt.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/4/7.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//


#import "SAFlushHTTPBodyInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAFlushHTTPBodyInterceptor (Encrypt)

- (NSDictionary *)sensorsdata_buildBodyWithFlowData:(SAFlowData *)flowData;

@end

NS_ASSUME_NONNULL_END
