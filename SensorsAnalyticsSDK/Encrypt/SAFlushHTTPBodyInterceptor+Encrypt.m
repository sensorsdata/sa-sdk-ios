//
// SAFlushHTTPBodyInterceptor+Encrypt.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/4/7.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAFlushHTTPBodyInterceptor+Encrypt.h"
#import "SAEncryptManager.h"
#import "SAEventRecord.h"
#import "SAConstants+Private.h"
#import "SAConfigOptions+EncryptPrivate.h"

@interface SAConfigOptions ()

@property (nonatomic, assign) BOOL enableEncrypt;

@end

@implementation SAFlushHTTPBodyInterceptor (Encrypt)

- (NSDictionary *)sensorsdata_buildBodyWithFlowData:(SAFlowData *)flowData {
    NSMutableDictionary *bodyData = [NSMutableDictionary dictionary];
    bodyData[kSAFlushBodyKeyGzip] = @(flowData.gzipCode);
    bodyData[kSAFlushBodyKeyData] = flowData.json;
    if (flowData.gzipCode == SAFlushGzipCodePlainText) {
        return [self sensorsdata_buildBodyWithFlowData:flowData];
    }
    return [bodyData copy];
}

@end
