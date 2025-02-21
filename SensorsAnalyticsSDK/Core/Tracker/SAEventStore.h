//
// SAEventStore.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/6/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAEventRecord.h"

NS_ASSUME_NONNULL_BEGIN

/// 默认存储表名和文件名
extern NSString * const kSADatabaseNameKey;
extern NSString * const kSADatabaseDefaultFileName;

@interface SAEventStore : NSObject

//serial queue for database read and write
@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;

/// All event record count
@property (nonatomic, readonly) NSUInteger count;

/**
 *  @abstract
 *  根据传入的文件路径初始化
 *
 *  @param filePath 传入的数据文件路径
 *
 *  @return 初始化的结果
 */
- (instancetype)initWithFilePath:(NSString *)filePath;

+ (instancetype)eventStoreWithFilePath:(NSString *)filePath;

/// fetch first records with a certain size
/// @param recordSize record size
/// @param instantEvent instant event or not
- (NSArray<SAEventRecord *> *)selectRecords:(NSUInteger)recordSize isInstantEvent:(BOOL)instantEvent;


/// insert single record
/// @param record event record
- (BOOL)insertRecord:(SAEventRecord *)record;


- (BOOL)updateRecords:(NSArray<NSString *> *)recordIDs status:(SAEventRecordStatus)status;


/// delete records with IDs
/// @param recordIDs event record IDs
- (BOOL)deleteRecords:(NSArray<NSString *> *)recordIDs;


/// delete all records from database
- (BOOL)deleteAllRecords;

- (NSUInteger)recordCountWithStatus:(SAEventRecordStatus)status;

@end

NS_ASSUME_NONNULL_END
