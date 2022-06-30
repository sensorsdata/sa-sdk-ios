//
// SAFlushHTTPBodyInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/11.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAFlushHTTPBodyInterceptor.h"
#import "NSString+SAHashCode.h"
#import "SAGzipUtility.h"
#import "SAEventRecord.h"

@interface SAConfigOptions ()

@property (nonatomic, assign) BOOL enableEncrypt;

@end

@implementation SAFlushHTTPBodyInterceptor

// 2. 完成 HTTP 请求拼接
- (NSData *)buildBodyWithJSONString:(NSString *)jsonString isEncrypted:(BOOL)isEncrypted {
    int gzip = 1; // gzip = 9 表示加密编码
    if (isEncrypted) {
        // 加密数据已{经做过 gzip 压缩和 base64 处理了，就不需要再处理。
        gzip = 9;
    } else {
        // 使用gzip进行压缩
        NSData *zippedData = [SAGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        // base64
        jsonString = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    }
    int hashCode = [jsonString sensorsdata_hashCode];
    jsonString = [jsonString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSString *bodyString = [NSString stringWithFormat:@"crc=%d&gzip=%d&data_list=%@", hashCode, gzip, jsonString];
    return [bodyString dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    NSParameterAssert(input.records.count > 0);

    BOOL isEncrypted = input.configOptions.enableEncrypt && input.records.firstObject.isEncrypted;
    input.HTTPBody = [self buildBodyWithJSONString:input.json isEncrypted:isEncrypted];
    completion(input);
}

@end
