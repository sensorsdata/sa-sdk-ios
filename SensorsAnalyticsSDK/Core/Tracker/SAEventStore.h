//
// SAEventStore.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/6/18.
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

#import <Foundation/Foundation.h>
#import "SAEventRecord.h"

NS_ASSUME_NONNULL_BEGIN

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

/// fetch first records with a certain size
/// @param recordSize record size
- (NSArray<SAEventRecord *> *)selectRecords:(NSUInteger)recordSize;


/// insert single record
/// @param record event record
- (BOOL)insertRecord:(SAEventRecord *)record;


- (BOOL)updateRecords:(NSArray<NSString *> *)recordIDs status:(SAEventRecordStatus)status;


/// delete records with IDs
/// @param recordIDs event record IDs
- (BOOL)deleteRecords:(NSArray<NSString *> *)recordIDs;


/// delete all records from database
- (BOOL)deleteAllRecords;

@end

NS_ASSUME_NONNULL_END
