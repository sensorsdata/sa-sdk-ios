//
// SAFlowData.m
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAFlowData.h"
#import "SAIdentifier.h"
#import "SAConstants+Private.h"

static NSString * const kSAFlowDataEventObject = @"event_object";
static NSString * const kSAFlowDataIdentifier = @"identifier";

/// 单条数据记录
static NSString * const kSAFlowDataRecord = @"record";
static NSString * const kSAFlowDataJSON = @"json";
static NSString * const kSAFlowDataHTTPBody = @"http_body";
static NSString * const kSAFlowDataRecords = @"records";
static NSString * const kSAFlowDataRecordIDs = @"record_ids";

static NSString * const kSAFlowDataProperties = @"properties";
static NSString * const kSAFlowDataFlushSuccess = @"flush_success";
static NSString * const kSAFlowDataStatusCode = @"status_code";
static NSString * const kSAFlowDataFlushCookie = @"flush_cookie";
static NSString * const kSAFlowDataRepeatCount = @"repeat_count";
static NSString * const kSAFlowDataGzipCode = @"gzip_code";

@implementation SAFlowData

- (instancetype)init {
    self = [super init];
    if (self) {
        _param = [NSMutableDictionary dictionary];
    }
    return self;
}

@end


#pragma mark -

@implementation SAFlowData (SAParam)

- (void)setParamWithKey:(NSString *)key value:(id _Nullable)value {
    if (value == nil) {
        [self.param removeObjectForKey:key];
    } else {
        self.param[key] = value;
    }
}

- (void)setRecord:(SAEventRecord *)record {
    [self setParamWithKey:kSAFlowDataRecord value:record];
}

- (SAEventRecord *)record {
    return self.param[kSAFlowDataRecord];

}

- (void)setJson:(NSString *)json {
    [self setParamWithKey:kSAFlowDataJSON value:json];
}

- (NSString *)json {
    return self.param[kSAFlowDataJSON];
}

- (void)setHTTPBody:(NSData *)HTTPBody {
    [self setParamWithKey:kSAFlowDataHTTPBody value:HTTPBody];
}

- (NSData *)HTTPBody {
    return self.param[kSAFlowDataHTTPBody];
}

- (void)setRecords:(NSArray<SAEventRecord *> *)records {
    [self setParamWithKey:kSAFlowDataRecords value:records];
}

- (NSArray<SAEventRecord *> *)records {
    return self.param[kSAFlowDataRecords];
}

- (void)setRecordIDs:(NSArray<NSString *> *)recordIDs {
    [self setParamWithKey:kSAFlowDataRecordIDs value:recordIDs];
}

- (NSArray<NSString *> *)recordIDs {
    return self.param[kSAFlowDataRecordIDs];
}

- (void)setEventObject:(SABaseEventObject *)eventObject {
    [self setParamWithKey:kSAFlowDataEventObject value:eventObject];
    self.isInstantEvent = eventObject.isInstantEvent;
}

- (SABaseEventObject *)eventObject {
    return self.param[kSAFlowDataEventObject];
}

- (void)setIdentifier:(SAIdentifier *)identifier {
    [self setParamWithKey:kSAFlowDataIdentifier value:identifier];
}

- (SAIdentifier *)identifier {
    return self.param[kSAFlowDataIdentifier];
}

- (void)setProperties:(NSDictionary *)properties {
    [self setParamWithKey:kSAFlowDataProperties value:properties];
}

- (NSDictionary *)properties {
    return self.param[kSAFlowDataProperties];
}

- (void)setFlushSuccess:(BOOL)flushSuccess {
    [self setParamWithKey:kSAFlowDataFlushSuccess value:@(flushSuccess)];
}

- (BOOL)flushSuccess {
    return [self.param[kSAFlowDataFlushSuccess] boolValue];
}

- (void)setStatusCode:(NSInteger)statusCode {
    [self setParamWithKey:kSAFlowDataStatusCode value:@(statusCode)];
}

- (NSInteger)statusCode {
    return [self.param[kSAFlowDataStatusCode] integerValue];
}

- (NSString *)cookie {
    return self.param[kSAFlowDataFlushCookie];
}

- (void)setCookie:(NSString *)cookie {
    self.param[kSAFlowDataFlushCookie] = cookie;
}

- (void)setRepeatCount:(NSInteger)repeatCount {
    [self setParamWithKey:kSAFlowDataRepeatCount value:@(repeatCount)];
}

- (NSInteger)repeatCount {
    return [self.param[kSAFlowDataRepeatCount] integerValue];
}

- (void)setIsInstantEvent:(BOOL)isInstantEvent {
    [self setParamWithKey:kSAInstantEventKey value:[NSNumber numberWithBool:isInstantEvent]];
}

-(BOOL)isInstantEvent {
    return [self.param[kSAInstantEventKey] boolValue];
}

- (void)setGzipCode:(SAFlushGzipCode)gzipCode {
    [self setParamWithKey:kSAFlowDataGzipCode value:@(gzipCode)];
}

- (SAFlushGzipCode)gzipCode {
    return [self.param[kSAFlowDataGzipCode] integerValue];
}

@end
