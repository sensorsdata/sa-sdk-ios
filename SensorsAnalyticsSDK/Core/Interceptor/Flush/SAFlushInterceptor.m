//
// SAFlushInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/8.
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

#import "SAFlushInterceptor.h"
#import "SAHTTPSession.h"
#import "SAModuleManager.h"
#import "SAURLUtils.h"
#import "SAJSONUtil.h"
#import "SAEventRecord.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SALog.h"

NSString * const kSAFlushServerURL = @"serverURL";

#pragma mark -

@interface SAFlushInterceptor ()

@property (nonatomic, strong) dispatch_semaphore_t flushSemaphore;
@property (nonatomic, copy) NSString *serverURL;


@end

@implementation SAFlushInterceptor

+ (instancetype)interceptorWithParam:(NSDictionary *)param {
    SAFlushInterceptor *interceptor = [[SAFlushInterceptor alloc] init];
    interceptor.serverURL = param[kSAFlushServerURL];
    return interceptor;
}

- (dispatch_semaphore_t)flushSemaphore {
    if (!_flushSemaphore) {
        _flushSemaphore = dispatch_semaphore_create(0);
    }
    return _flushSemaphore;
}

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions || self.serverURL);
    NSParameterAssert(input.HTTPBody);

    // 当在程序终止或 debug 模式下，使用线程锁
    BOOL isWait = input.configOptions.flushBeforeEnterBackground || input.configOptions.debugMode != SensorsAnalyticsDebugOff;
    [self requestWithInput:input completion:^(BOOL success) {
        input.flushSuccess = success;
        if (isWait) {
            dispatch_semaphore_signal(self.flushSemaphore);
        } else {
            completion(input);
        }
    }];
    if (isWait) {
        dispatch_semaphore_wait(self.flushSemaphore, DISPATCH_TIME_FOREVER);
        completion(input);
    }
}

#pragma mark - build
- (void)requestWithInput:(SAFlowData *)input completion:(void (^)(BOOL success))completion {
    // 网络请求回调处理
    SAURLSessionTaskCompletionHandler handler = ^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
            input.message = [NSString stringWithFormat:@"%@ network failure: %@", self, error ? error : @"Unknown error"];
            return completion(NO);
        }

        NSInteger statusCode = response.statusCode;

        NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *messageDesc = nil;
        if (statusCode >= 200 && statusCode < 300) {
            messageDesc = @"\n【valid message】\n";
        } else {
            messageDesc = @"\n【invalid message】\n";
            if (statusCode >= 300 && input.configOptions.debugMode != SensorsAnalyticsDebugOff) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ flush failure with response '%@'.", self, urlResponseContent];
                [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
            }
        }

        NSArray *eventLogs = [self eventLogsWithRecoeds:input.records];
        SALogDebug(@"%@ %@: %@", self, messageDesc, eventLogs);

        if (statusCode != 200) {
            SALogError(@"%@ ret_code: %ld, ret_content: %@", self, statusCode, urlResponseContent);
        }

        input.statusCode = statusCode;
        // 1、开启 debug 模式，都删除；
        // 2、debugOff 模式下，只有 5xx & 404 & 403 不删，其余均删；
        BOOL successCode = (statusCode < 500 || statusCode >= 600) && statusCode != 404 && statusCode != 403;
        BOOL flushSuccess = input.configOptions.debugMode != SensorsAnalyticsDebugOff || successCode;
        if (!flushSuccess) {
            input.message = [NSString stringWithFormat:@"flush failed, statusCode: %ld",statusCode];
        }
        completion(flushSuccess);
    };

    NSURLRequest *request = [self buildFlushRequestWithInput:input];
    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:handler];
    [task resume];
}

- (NSURLRequest *)buildFlushRequestWithInput:(SAFlowData *)input {
    NSString *urlString = self.serverURL ?: input.configOptions.serverURL;
    NSURL *serverURL = [SAURLUtils buildServerURLWithURLString:urlString debugMode:input.configOptions.debugMode];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:serverURL];
    request.timeoutInterval = 30;
    request.HTTPMethod = @"POST";
    request.HTTPBody = input.HTTPBody;
    // 普通事件请求，使用标准 UserAgent
    [request setValue:@"SensorsAnalytics iOS SDK" forHTTPHeaderField:@"User-Agent"];
    if (input.configOptions.debugMode == SensorsAnalyticsDebugOnly) {
        [request setValue:@"true" forHTTPHeaderField:@"Dry-Run"];
    }

    if (input.cookie) {
        [request setValue:input.cookie forHTTPHeaderField:@"Cookie"];
    }

    return request;
}

- (NSArray<NSDictionary *> *)eventLogsWithRecoeds:(NSArray <SAEventRecord *>*)records {
    if (records.count == 0) {
        return nil;
    }
    NSMutableArray <NSDictionary *>*eventSources = [NSMutableArray arrayWithCapacity:records.count];
    for (SAEventRecord *record in records) {
        if(!record.isEncrypted) {
            [eventSources addObject:record.event];
            continue;
        }

        // 针对加密的数据，只需要打印合并后的数据即可
        if(record.event[kSAEncryptRecordKeyPayloads]){
            [eventSources addObject:record.event];
        }
    }
    return [eventSources copy];
}

@end
