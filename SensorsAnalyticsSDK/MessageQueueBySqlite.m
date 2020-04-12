//
//  MessageQueueBySqlite.m
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/7.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <sqlite3.h>

#import "SAJSONUtil.h"
#import "MessageQueueBySqlite.h"
#import "SALog.h"
#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"

static const UInt64 kMessageCachesMaxSize = 10000; // 内存缓存时的最大缓存条数
static const NSUInteger kRemoveFirstRecordsDefaultCount = 100; // 超过最大缓存条数时默认的删除条数

@interface MessageQueueBySqlite ()

@property (nonatomic, copy) NSString *filePath;
/// store data in memory
@property (nonatomic, strong) NSMutableArray<NSString *> *messageCaches;
/// is the database init or not
@property (nonatomic, assign) BOOL isDatabaseInitialized;

@end

@implementation MessageQueueBySqlite {
    sqlite3 *_database;
    SAJSONUtil *_jsonUtil;
    NSInteger _dbMessageCount;
    CFMutableDictionaryRef _dbStmtCache;
}

#pragma mark - Life Cycle

- (void)dealloc {
    [self closeDatabase];
}

- (id)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _jsonUtil = [[SAJSONUtil alloc] init];
        self.filePath = filePath;
        
        [self initializeDatabase];
        [self createStmtCache];
        [self openDatabase];
    }
    return self;
}

- (void)initializeDatabase {
    self.isDatabaseInitialized = (sqlite3_initialize() == SQLITE_OK);
    
    if (self.isDatabaseInitialized) {
        SALogDebug(@"Success to initialize SQLite.");
    } else {
        SALogError(@"Failed to initialize SQLite.");
    }
}

- (void)createStmtCache {
    CFDictionaryKeyCallBacks keyCallbacks = kCFCopyStringDictionaryKeyCallBacks;
    CFDictionaryValueCallBacks valueCallbacks = { 0 };
    _dbStmtCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &keyCallbacks, &valueCallbacks);
}

- (BOOL)openDatabase {
    if (_database) {
        return YES;
    }
    
    if (!self.isDatabaseInitialized) {
        // 如果初始化失败，不再尝试打开数据库
        return NO;
    }
    
    int result = sqlite3_open_v2([self.filePath UTF8String], &_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    if ((result == SQLITE_OK) && [self createTable]) {
        SALogDebug(@"Success to open SQLite db.");
        
        return YES;
    } else {
        _database = NULL;
        SALogError(@"Failed to open SQLite db.");
        
        return NO;
    }
}

- (BOOL)createTable {
    NSString *sql = @"create table if not exists dataCache (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, content TEXT)";
    if ([self databaseExecute:sql]) {
        _dbMessageCount = [self sqliteCount];
        SALogDebug(@"Create dataCache table success, current count is %lu", _dbMessageCount);
        
        return YES;
    } else {
        SALogError(@"Create dataCache table fail.");
        
        return NO;
    }
}

#pragma mark - Public Methods

- (void)addObject:(id)obj withType:(NSString *)type {
    if (!obj || ![type isKindOfClass:[NSString class]]) {
        SALogError(@"%@ input parameter is invalid for addObject", self);
        return;
    }
    
    if ([self databaseCheck]) {
        [self addObjectToDatabase:obj withType:type isFromCache:NO];
    } else {
        [self addObjectToCache:obj];
    }
}

- (NSArray *)getFirstRecords:(NSUInteger)recordSize withType:(NSString *)type {
    if (recordSize == 0) {
        return @[];
    }
    
    if ([self databaseCheck]) {
        return [self fetchFirstRecordsFromDatabase:recordSize];
    }
    
    return [self fetchFirstRecordsFromCache:recordSize];
}

- (void)deleteAll {
    [self.messageCaches removeAllObjects];
    
    if ([self databaseCheck]) {
        NSString *sql = @"DELETE FROM dataCache";
        if (![self databaseExecute:sql]) {
            SALogError(@"Failed to delete record");
        }
        
        _dbMessageCount = [self sqliteCount];
    } else {
        SALogError(@"Failed to delete record because the database failed to open");
    }
}

- (BOOL)removeFirstRecords:(NSUInteger)recordSize withType:(NSString *)type {
    if (recordSize == 0) {
        return YES;
    }
    
    // 删除时不尝试打开数据库，因为可能会导致 getFirstRecords 和 removeFirstRecords 不一致
    if (_database) {
        return [self removeFirstRecordsFromDatabase:recordSize];
    }
    
    [self removeFirstRecordsFromCache:recordSize];
    return YES;
}

- (NSInteger)count {
    return _dbMessageCount + self.messageCaches.count;
}

- (BOOL)vacuum {
#ifdef SENSORS_ANALYTICS_ENABLE_VACUUM
    @try {
        if (![self databaseCheck]) {
            SALogError(@"Failed to VACUUM record because the database failed to open");
            return NO;
        }
        
        NSString *sql = @"VACUUM";
        if (![self databaseExecute:sql]) {
            SALogError(@"Failed to VACUUM record");
            return NO;
        }
        return YES;
    } @catch (NSException *exception) {
        return NO;
    }
#else
    return YES;
#endif
}

#pragma mark - Private Methods

- (BOOL)databaseExecute:(NSString *)sql {
    if (sql.length == 0) return NO;
    if (!_database) return NO;
    
    @try {
        char *error = NULL;
        int result = sqlite3_exec(_database, sql.UTF8String, NULL, NULL, &error);
        if (error) {
            SALogError(@"%@ database execute sql:%@ error (%d): %s", self, sql, result, error);
            sqlite3_free(error);
        }
        
        return result == SQLITE_OK;
    } @catch (NSException *exception) {
        SALogError(@"%@ database execute sql:%@ exception: %@", self, sql, exception);
        return NO;
    }
}

- (void)addObjectToCache:(id)obj {
    if (!obj) {
        SALogError(@"%@ input parameter is invalid for addObjectToCache", self);
        return;
    }
    
    // 数据缓存到内存中，如果最大缓存条数大于 10000，可能导致内存占用过大
    if (self.messageCaches.count >= kMessageCachesMaxSize) {
        SALogError(@"AddObjectToCache touch MAX_MESSAGE_SIZE:10000, try to delete some old events");
        [self removeFirstRecordsFromCache:kRemoveFirstRecordsDefaultCount];
    }
    
    @try {
        NSString *jsonString = [self buildJSONStringWithObject:obj];
        if (jsonString.length > 0) {
            // 能够转成 json 字符串
            [self.messageCaches addObject:jsonString];
            SALogDebug(@"insert dataCache into memory success, current count is %lu", self.messageCaches.count);
        } else {
            // 不能转成 json 字符串
            SALogError(@"insert dataCache into memory error");
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
}

- (void)addObjectToDatabase:(id)obj withType:(NSString *)type isFromCache:(BOOL)isFromCache {
    if (!obj || ![type isKindOfClass:[NSString class]]) {
        SALogError(@"%@ input parameter is invalid for addObjectToDatabase", self);
        return;
    }
    
    UInt64 maxCacheSize = [SensorsAnalyticsSDK sharedInstance].configOptions.maxCacheSize;
    if (_dbMessageCount >= maxCacheSize) {
        SALogError(@"AddObjectToDatabase touch MAX_MESSAGE_SIZE:%llu, try to delete some old events", maxCacheSize);
        BOOL ret = [self removeFirstRecordsFromDatabase:kRemoveFirstRecordsDefaultCount];
        if (ret) {
            _dbMessageCount = [self sqliteCount];
        } else {
            SALogError(@"AddObjectToDatabase touch MAX_MESSAGE_SIZE:%llu, try to delete some old events FAILED", maxCacheSize);
            return;
        }
    }
    
    NSString *jsonString = nil;
    if (isFromCache) {
        // 数据从缓存中来，已经是处理成 NSString 的结果，不需要再次进行处理
        jsonString = obj;
    } else {
        // 数据从外部进来，需要进行处理
        jsonString = [self buildJSONStringWithObject:obj];
    }
    
    NSString *query = @"INSERT INTO dataCache(type, content) values(?, ?)";
    sqlite3_stmt *insertStatement = [self dbCacheStmt:query];
    int rc;
    if (insertStatement && jsonString.length > 0) {
        sqlite3_bind_text(insertStatement, 1, [type UTF8String], -1, SQLITE_TRANSIENT);
        @try {
            sqlite3_bind_text(insertStatement, 2, [jsonString UTF8String], -1, SQLITE_TRANSIENT);
        } @catch (NSException *exception) {
            SALogError(@"Found NON UTF8 String, ignore");
            return;
        }
        rc = sqlite3_step(insertStatement);
        if (rc != SQLITE_DONE) {
            SALogError(@"insert into dataCache table of sqlite fail, rc is %d", rc);
        } else {
            _dbMessageCount++;
            SALogDebug(@"insert into dataCache table of sqlite success, current count is %lu", _dbMessageCount);
        }
    } else {
        SALogError(@"insert into dataCache table of sqlite error");
    }
}

- (NSString *)buildJSONStringWithObject:(id)obj {
    NSData *jsonData = [_jsonUtil JSONSerializeObject:obj];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSArray *)fetchFirstRecordsFromCache:(NSUInteger)recordSize {
    if ((self.messageCaches.count == 0) || (recordSize == 0)) {
        return @[];
    }
    
    NSUInteger actualRecordSize = MIN(recordSize, self.messageCaches.count);
    NSArray<NSString *> *firstRecords = [self.messageCaches subarrayWithRange:NSMakeRange(0, actualRecordSize)];
    
    NSMutableArray *contentArray = [[NSMutableArray alloc] init];
    
    for (NSString *record in firstRecords) {
        @try {
            __weak typeof(self) weakSelf = self;
            NSString *handledRecord = [self addFlushTimeToRecord:record withDeleteBlock:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                [strongSelf.messageCaches removeObject:record];
            }];
            
            if (handledRecord.length > 0) {
                [contentArray addObject:handledRecord];
            }
        } @catch (NSException *exception) {
            SALogError(@"%@ error: %@", self, exception);
        }
    }
    
    return [NSArray arrayWithArray:contentArray];
}

- (NSArray *)fetchFirstRecordsFromDatabase:(NSUInteger)recordSize {
    if ((_dbMessageCount == 0) || (recordSize == 0)) {
        return @[];
    }
    
    NSString *query = [NSString stringWithFormat:@"SELECT id,content FROM dataCache ORDER BY id ASC LIMIT %lu", (unsigned long)recordSize];
    sqlite3_stmt *stmt = [self dbCacheStmt:query];
    if (!stmt) {
        SALogError(@"Failed to prepare statement, error:%s", sqlite3_errmsg(_database));
        return nil;
    }
    
    NSMutableArray *contentArray = [[NSMutableArray alloc] init];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        @try {
            char *jsonChar = (char *)sqlite3_column_text(stmt, 1);
            if (!jsonChar) {
                SALogError(@"Failed to query column_text, error:%s", sqlite3_errmsg(_database));
                return nil;
            }
            
            __weak typeof(self) weakSelf = self;
            NSString *handledRecord = [self addFlushTimeToRecord:[NSString stringWithUTF8String:jsonChar] withDeleteBlock:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                char *idChar = (char *)sqlite3_column_text(stmt, 0);
                NSInteger idIndex = [[NSString stringWithUTF8String:idChar] integerValue];
                [strongSelf deleteDatabaseRecordWithId:idIndex];
            }];
            
            if (handledRecord.length > 0) {
                [contentArray addObject:handledRecord];
            }
        } @catch (NSException *exception) {
            SALogError(@"Found NON UTF8 String, ignore");
        }
    }
    
    return [NSArray arrayWithArray:contentArray];
}

- (NSString *)addFlushTimeToRecord:(NSString *)record withDeleteBlock:(void (^)(void))deleteBlock {
    NSData *jsonData = [record dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        if (deleteBlock) {
            deleteBlock();
        }
        return nil;
    }
    
    NSError *err;
    NSMutableDictionary *eventDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&err];
    if (!err && eventDict) {
        UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
        [eventDict setValue:@(time) forKey:SA_EVENT_FLUSH_TIME];
    } else { //删除内容为空的数据
        if (deleteBlock) {
            deleteBlock();
        }
        return nil;
    }
    return [[NSString alloc] initWithData:[_jsonUtil JSONSerializeObject:eventDict] encoding:NSUTF8StringEncoding];
}

/// 从数据库中删除某条数据
- (BOOL)deleteDatabaseRecordWithId:(NSInteger)index {
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM dataCache WHERE id = %ld", (long)index];
    if ([self databaseExecute:sql]) {
        _dbMessageCount--;
        return YES;
    } else {
        SALogError(@"Failed to delete record");
        return NO;
    }
}

- (void)removeFirstRecordsFromCache:(NSUInteger)recordSize {
    if ((self.messageCaches.count == 0) || (recordSize == 0)) {
        return;
    }
    
    NSUInteger actualRemoveSize = MIN(recordSize, self.messageCaches.count);
    [self.messageCaches removeObjectsInRange:NSMakeRange(0, actualRemoveSize)];
}

- (BOOL)removeFirstRecordsFromDatabase:(NSUInteger)recordSize {
    if ((_dbMessageCount == 0) || (recordSize == 0)) {
        return YES;
    }
    
    NSUInteger removeSize = MIN(recordSize, _dbMessageCount);
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM dataCache WHERE id IN (SELECT id FROM dataCache ORDER BY id ASC LIMIT %lu);", (unsigned long)removeSize];
    if (![self databaseExecute:sql]) {
        SALogError(@"Failed to delete record from database");
        return NO;
    }
    
    _dbMessageCount = [self sqliteCount];
    return YES;
}

- (void)closeDatabase {
    if (_dbStmtCache) CFRelease(_dbStmtCache);
    _dbStmtCache = NULL;

    sqlite3_close(_database);
    sqlite3_shutdown();
    SALogDebug(@"%@ close database", self);
}

- (BOOL)databaseCheck {
    if (![self openDatabase]) {
        return NO;
    }
    
    // 数据库打开成功，将内存中的数据读入数据库中
    if (self.messageCaches.count > 0) {
        for (id obj in self.messageCaches) {
            
            // 目前 add object 的 type 都是 Post
            [self addObjectToDatabase:obj withType:@"Post" isFromCache:YES];
        }
        
        [self.messageCaches removeAllObjects];
    }
    
    return YES;
}

- (NSInteger)sqliteCount {
    NSString *query = @"select count(*) from dataCache";
    NSInteger count = 0;
    sqlite3_stmt *statement = [self dbCacheStmt:query];
    if (statement) {
        while (sqlite3_step(statement) == SQLITE_ROW)
            count = sqlite3_column_int(statement, 0);
    } else {
        SALogError(@"Failed to prepare statement");
    }
    return count;
}

- (sqlite3_stmt *)dbCacheStmt:(NSString *)sql {
    if (sql.length == 0 || !_dbStmtCache) return NULL;
    sqlite3_stmt *stmt = (sqlite3_stmt *)CFDictionaryGetValue(_dbStmtCache, (__bridge const void *)(sql));
    if (!stmt) {
        int result = sqlite3_prepare_v2(_database, sql.UTF8String, -1, &stmt, NULL);
        if (result != SQLITE_OK) {
            SALogError(@"%s line:%d sqlite stmt prepare error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_database));
            return NULL;
        }
        CFDictionarySetValue(_dbStmtCache, (__bridge const void *)(sql), stmt);
    } else {
        sqlite3_reset(stmt);
    }
    return stmt;
}

#pragma mark - Getters and Setters

- (NSMutableArray<NSString *> *)messageCaches {
    if (!_messageCaches) {
        _messageCaches = [NSMutableArray array];
    }
    return _messageCaches;
}

@end
