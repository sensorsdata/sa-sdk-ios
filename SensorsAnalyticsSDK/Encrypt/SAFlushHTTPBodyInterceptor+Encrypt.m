//
// SAFlushHTTPBodyInterceptor+Encrypt.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/4/7.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
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
