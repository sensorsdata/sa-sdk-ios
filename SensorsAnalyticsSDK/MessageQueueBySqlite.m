//
//  MessageQueueBySqlite.m
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/7.
//  Copyright (c) 2015年 SensorsData. All rights reserved.
//

#import <sqlite3.h>

#import "JSONUtil.h"
#import "MessageQueueBySqlite.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK.h"

#define MAX_MESSAGE_SIZE 10000   // 最多缓存10000条

@implementation MessageQueueBySqlite {
    sqlite3 *_database;
    JSONUtil *_jsonUtil;
    NSUInteger _messageCount;
}

- (void) closeDatabase {
    sqlite3_close(_database);
    sqlite3_shutdown();
    SADebug(@"%@ close database", self);
}

- (void) dealloc {
    [self closeDatabase];
}

- (id)initWithFilePath:(NSString *)filePath {
    self = [super init];
    _jsonUtil = [[JSONUtil alloc] init];
    if (sqlite3_initialize() != SQLITE_OK) {
        SAError(@"failed to initialize SQLite.");
        return nil;
    }
    if (sqlite3_open_v2([filePath UTF8String], &_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) == SQLITE_OK ) {
        // 创建一个缓存表
        NSString *_sql = @"create table if not exists dataCache (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, content TEXT)";
        char *errorMsg;
        if (sqlite3_exec(_database, [_sql UTF8String], NULL, NULL, &errorMsg)==SQLITE_OK) {
            SADebug(@"Create dataCache Success.");
        } else {
            SAError(@"Create dataCache Failure %s",errorMsg);
            return nil;
        }
        _messageCount = [self sqliteCount];
        SADebug(@"SQLites is opened. current count is %ul", _messageCount);
    } else {
        SAError(@"failed to open SQLite db.");
        return nil;
    }
    return self;
}

- (void)addObejct:(id)obj withType:(NSString *)type {
    UInt64 maxCacheSize = [[SensorsAnalyticsSDK sharedInstance] getMaxCacheSize];
    if (_messageCount >= maxCacheSize) {
        SAError(@"touch MAX_MESSAGE_SIZE:%d, try to delete some old events", maxCacheSize);
        BOOL ret = [self removeFirstRecords:100 withType:@"Post"];
        if (ret) {
            _messageCount = [self sqliteCount];
        } else {
            SAError(@"touch MAX_MESSAGE_SIZE:%d, try to delete some old events FAILED", maxCacheSize);
            return;
        }
    }
    NSData* jsonData = [_jsonUtil JSONSerializeObject:obj];
    NSString* query = @"INSERT INTO dataCache(type, content) values(?, ?)";
    sqlite3_stmt *insertStatement;
    int rc;
    rc = sqlite3_prepare_v2(_database, [query UTF8String],-1, &insertStatement, nil);
    if (rc == SQLITE_OK) {
        sqlite3_bind_text(insertStatement, 1, [type UTF8String], -1, SQLITE_TRANSIENT);
        @try {
            sqlite3_bind_text(insertStatement, 2, [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] UTF8String], -1, SQLITE_TRANSIENT);
        } @catch (NSException *exception) {
            SAError(@"Found NON UTF8 String, ignore");
            return;
        }
        rc = sqlite3_step(insertStatement);
        if(rc != SQLITE_DONE) {
            SAError(@"insert into dataCache fail, rc is %d", rc);
        } else {
            sqlite3_finalize(insertStatement);
            _messageCount ++;
            SADebug(@"insert into dataCache success, current count is %lu", _messageCount);
        }
    } else {
        SAError(@"insert into dataCache error");
    }
}



- (NSArray *) getFirstRecords:(NSUInteger)recordSize withType:(NSString *)type {
    if (_messageCount == 0) {
        return @[];
    }
    NSMutableArray* contentArray = [[NSMutableArray alloc] init];
    NSString* query = [NSString stringWithFormat:@"SELECT content FROM dataCache ORDER BY id ASC LIMIT %lu", (unsigned long)recordSize];
    sqlite3_stmt* stmt = NULL;
    int rc = sqlite3_prepare_v2(_database, [query UTF8String], -1, &stmt, NULL);
    if(rc == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            @try {
                NSData *jsonData = [[NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 0)] dataUsingEncoding:NSUTF8StringEncoding];
                NSError *err;
                NSMutableDictionary *eventDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                                 options:NSJSONReadingMutableContainers
                                                                                   error:&err];
                if (!err) {
                    UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
                    [eventDict setValue:@(time) forKey:@"_flush_time"];
                }

                [contentArray addObject:[[NSString alloc] initWithData:[_jsonUtil JSONSerializeObject:eventDict] encoding:NSUTF8StringEncoding]];
            } @catch (NSException *exception) {
                SAError(@"Found NON UTF8 String, ignore");
            }
        }
        sqlite3_finalize(stmt);
    }
    else {
        SAError(@"Failed to prepare statement with rc:%d, error:%s", rc, sqlite3_errmsg(_database));
        return nil;
    }
    return [NSArray arrayWithArray:contentArray];
}

- (void) deleteAll {
    NSString* query = @"DELETE FROM dataCache";
    char* errMsg;
    @try {
        if (sqlite3_exec(_database, [query UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
            SAError(@"Failed to delete record msg=%s", errMsg);
        }
    } @catch (NSException *exception) {
        SAError(@"Failed to delete record exception=%@",exception);
    }

    _messageCount = [self sqliteCount];
}

- (BOOL) removeFirstRecords:(NSUInteger)recordSize withType:(NSString *)type {
    NSUInteger removeSize = MIN(recordSize, _messageCount);
    NSString* query = [NSString stringWithFormat:@"DELETE FROM dataCache WHERE id IN (SELECT id FROM dataCache ORDER BY id ASC LIMIT %lu);", (unsigned long)removeSize];
    char* errMsg;
    @try {
        if (sqlite3_exec(_database, [query UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
            SAError(@"Failed to delete record msg=%s", errMsg);
            return NO;
        }
    } @catch (NSException *exception) {
        SAError(@"Failed to delete record exception=%@",exception);
        return NO;
    }
    _messageCount = [self sqliteCount];
    return YES;
}

- (NSUInteger) count {
    return _messageCount;
}

- (NSInteger) sqliteCount {
    NSString* query = @"select count(*) from dataCache";
    sqlite3_stmt* statement = NULL;
    NSInteger count = -1;
    int rc = sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, NULL);
    if(rc == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            count = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
    }
    else {
        SAError(@"Failed to prepare statement, rc is %d", rc);
    }
    return count;
}

- (BOOL) vacuum {
#ifdef SENSORS_ANALYTICS_ENABLE_VACUUM
    @try {
        NSString* query = @"VACUUM";
        char* errMsg;
        if (sqlite3_exec(_database, [query UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
            SAError(@"Failed to delete record msg=%s", errMsg);
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

@end
