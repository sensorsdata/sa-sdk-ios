//
// SAFlushHTTPBodyInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAFlushHTTPBodyInterceptor.h"
#import "NSString+SAHashCode.h"
#import "SAGzipUtility.h"
#import "SAEventRecord.h"
#import "SAConstants+Private.h"

@implementation SAFlushHTTPBodyInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    NSParameterAssert(input.records.count > 0);

    NSData *httpBody = [self buildBodyWithInput:input];
    if (!httpBody) {
        input.state = SAFlowStateError;
        input.message = @"Event message base64Encoded or Gzip compression failed, End the track flow";
        return completion(input);
    }

    input.HTTPBody = httpBody;
    completion(input);
}

- (NSData *)buildBodyWithInput:(SAFlowData *)input {
    NSDictionary *bodyDic = [self buildBodyWithFlowData:input];
    if (!bodyDic) {
        return nil;
    }
    NSNumber *gzip = bodyDic[kSAFlushBodyKeyGzip];
    NSString *data = bodyDic[kSAFlushBodyKeyData];
    int hashCode = [data sensorsdata_hashCode];
    if (!data) {
        return nil;
    }
    data = [data stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSString *bodyString = [NSString stringWithFormat:@"crc=%d&gzip=%d&data_list=%@", hashCode, [gzip intValue], data];
    if (input.isInstantEvent) {
        bodyString = [bodyString stringByAppendingString:@"&instant_event=true"];
    }
    if (input.isAdsEvent) {
        bodyString = [bodyString stringByAppendingString:@"&sink_name=mirror"];
    }
    return [bodyString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSDictionary *)buildBodyWithFlowData:(SAFlowData *)flowData {
    NSString *jsonString = flowData.json;
    // 使用gzip进行压缩
    NSData *zippedData = [SAGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    if (!zippedData) {
        return nil;
    }
    // base64
    NSString *base64String = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    if (!base64String || ![base64String isKindOfClass:NSString.class]) {
        return nil;
    }
    NSDictionary *bodyDic = @{kSAFlushBodyKeyGzip: @(kSAFlushGzipCodePlainText), kSAFlushBodyKeyData: base64String};
    return bodyDic;
}

@end
