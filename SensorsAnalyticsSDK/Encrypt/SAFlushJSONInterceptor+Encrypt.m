//
// SASAFlushJSONInterceptor+Encrypt.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/4/7.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAFlushJSONInterceptor+Encrypt.h"
#import "SAEventRecord.h"
#import "SAEncryptManager.h"
#import "SAConfigOptions+EncryptPrivate.h"
#import "SAJSONUtil.h"
#import "SAConstants+Private.h"

@interface SAConfigOptions ()

@property (nonatomic, assign) BOOL enableEncrypt;

@end

@implementation SAFlushJSONInterceptor (Encrypt)

- (NSString *)sensorsdata_buildJSONStringWithFlowData:(SAFlowData *)flowData {
    if (flowData.isAdsEvent) {
        return [self sat_buildEncryptJSONStringWithFlowData:flowData];
    }
    NSArray <SAEventRecord *> *records = flowData.records;
    BOOL enableEncrypt = [SAEncryptManager defaultManager].configOptions.enableEncrypt;
    BOOL firstRecordsEncrypted = records.firstObject.isEncrypted;
    if (enableEncrypt) {
        if (firstRecordsEncrypted) {
            return [self buildEncryptJSONStringWithFlowData:flowData];
        }
        return [self sensorsdata_buildJSONStringWithFlowData:flowData];
    }
    BOOL enableFlushEncrypt = [SAEncryptManager defaultManager].configOptions.enableFlushEncrypt;
    if (!enableFlushEncrypt) {
        return [self sensorsdata_buildJSONStringWithFlowData:flowData];
    }
    if (firstRecordsEncrypted) {
        return [self buildEncryptJSONStringWithFlowData:flowData];
    }
    return [self buildFlushEncryptJSONStringWithFlowData:flowData];
}

- (NSString *)sat_buildEncryptJSONStringWithFlowData:(SAFlowData *)flowData {
    NSArray <SAEventRecord *> *records = flowData.records;
    BOOL firstRecordsEncrypted = records.firstObject.isEncrypted;
    if (firstRecordsEncrypted) {
        return [self buildEncryptJSONStringWithFlowData:flowData];
    }
    return [self sensorsdata_buildJSONStringWithFlowData:flowData];
}

- (NSString *)buildEncryptJSONStringWithFlowData:(SAFlowData *)flowData {
    // 初始化用于保存合并后的事件数据
    NSArray <SAEventRecord *> *records = flowData.records;
    NSMutableArray *encryptRecords = [NSMutableArray arrayWithCapacity:records.count];
    // 用于保存当前存在的所有 ekey
    NSMutableArray *ekeys = [NSMutableArray arrayWithCapacity:records.count];
    for (SAEventRecord *record in records) {
        NSInteger index = [ekeys indexOfObject:record.ekey];
        if (index == NSNotFound) {
            [record removePayload];
            [encryptRecords addObject:record];

            [ekeys addObject:record.ekey];
        } else {
            [encryptRecords[index] mergeSameEKeyPayloadWithRecord:record];
        }
    }
    flowData.gzipCode = SAFlushGzipCodeEncrypt;
    return [self buildEncryptJSONStringWithRecords:encryptRecords];
}

- (NSString *)buildEncryptJSONStringWithRecords:(NSArray *)records {
    NSMutableArray *contents = [NSMutableArray arrayWithCapacity:records.count];
    for (SAEventRecord *record in records) {
        NSString *flushContent = [record flushContent];
        if (flushContent) {
            [contents addObject:flushContent];
        }
    }
    return [NSString stringWithFormat:@"[%@]", [contents componentsJoinedByString:@","]];
}

- (NSString *)buildFlushEncryptJSONStringWithFlowData:(SAFlowData *)flowData {
    NSArray <SAEventRecord *> *records = flowData.records;
    NSMutableArray *events = [NSMutableArray array];
    for (SAEventRecord *record in records) {
        NSDictionary *decryptedEvent = [self decryptEventRecord:record.event];
        if (decryptedEvent) {
            [events addObject:decryptedEvent];
            record.event = [NSMutableDictionary dictionaryWithDictionary:decryptedEvent];
        }
    }
    NSDictionary *encryptEvents = [[SAEncryptManager defaultManager] encryptJSONObject:events];
    if (!encryptEvents) {
        return [self sensorsdata_buildJSONStringWithFlowData:flowData];
    }
    NSMutableDictionary *tempEncryptEvents = [NSMutableDictionary dictionary];
    tempEncryptEvents[kSAEncryptRecordKeyPayloads] = encryptEvents[kSAEncryptRecordKeyPayload];
    tempEncryptEvents[kSAEncryptRecordKeyEKey] = encryptEvents[kSAEncryptRecordKeyEKey];
    tempEncryptEvents[kSAEncryptRecordKeyPKV] = encryptEvents[kSAEncryptRecordKeyPKV];
    UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
    tempEncryptEvents[kSAEncryptRecordKeyFlushTime] = @(time);
    flowData.gzipCode = SAFlushGzipCodeTransportEncrypt;
    return [SAJSONUtil stringWithJSONObject:@[tempEncryptEvents]];
}

- (NSDictionary *)decryptEventRecord:(NSDictionary *)eventRecord {
    if (!eventRecord[kSAEncryptRecordKeyPayload]) {
        return eventRecord;
    }
    NSDictionary *eventData = [[SAEncryptManager defaultManager] decryptEventRecord:eventRecord];
    return eventData;
}

@end
