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


#define MAX_MESSAGE_SIZE 1000   // 最多缓存1000条


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

- (id)initWithFilePath: (NSString*) filePath {
    self = [super init];
    _jsonUtil = [[JSONUtil alloc] init];
    if (sqlite3_initialize() != SQLITE_OK) {
        SAError(@"sqlite3_initialize fail");
        return nil;
    }
    if (sqlite3_open_v2( [filePath UTF8String], &_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) == SQLITE_OK ) {
        // 创建一个缓存表
        NSString *_sql = @"create table if not exists dataCache (id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT)";
        char *errorMsg;
        if (sqlite3_exec(_database, [_sql UTF8String], NULL, NULL, &errorMsg)==SQLITE_OK) {
            SADebug(@"Create dataCache Success.");
        }else {
            SAError(@"Create dataCache Failure %s",errorMsg);
            return nil;
        }
        _messageCount = [self sqliteCount];
        SADebug(@"SQLites is opened.current count is %ul", _messageCount);
    } else {
        SAError(@"create database fail");
        return nil;
    }
    return self;
}

- (void)addObejct:(id) obj {
    if (_messageCount >= MAX_MESSAGE_SIZE) {
        SAError(@"touch MAX_MESSAGE_SIZE:%d, do not insert", MAX_MESSAGE_SIZE);
        return;
    }
    NSData * jsonData = [_jsonUtil JSONSerializeObject:obj];
    NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *query = @"INSERT INTO dataCache(content) values(?)";
    sqlite3_stmt *insertStatement;
    int rc ;
    rc = sqlite3_prepare_v2(_database, [query UTF8String],-1, &insertStatement, nil);
    if (rc == SQLITE_OK) {
        sqlite3_bind_text(insertStatement, 1, [jsonString UTF8String], -1, SQLITE_TRANSIENT);
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



- (NSArray *) getFirstRecords:(NSUInteger) recordSize {
    if (_messageCount == 0) {
        return @[];
    }
    NSMutableArray * contentArray =[[NSMutableArray alloc] init];
    NSString *query = [NSString stringWithFormat:@"select content from dataCache order by id asc limit %lu", (unsigned long)recordSize];
    sqlite3_stmt* stmt = NULL;
    int rc = sqlite3_prepare_v2(_database, [query UTF8String], -1, &stmt, NULL);
    if(rc == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSString *content =[NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 0)];
            SADebug(@"content=%@", content);
            [contentArray addObject:content];
        }
        sqlite3_finalize(stmt);
    }
    else {
        SAError(@"Failed to prepare statement with rc:%d", rc);
        return nil;
    }
    return [NSArray arrayWithArray:contentArray];
    
    
}

- (BOOL) removeFirstRecords:(NSUInteger) recordSize {
    NSUInteger removeSize = MIN(recordSize, _messageCount);
    NSString *query  = [NSString stringWithFormat:@"delete from dataCache where id in (select id from dataCache order by id asc limit %lu);", removeSize];
    char * errMsg;
    if (sqlite3_exec(_database, [query UTF8String] ,NULL,NULL,&errMsg) != SQLITE_OK) {
        NSLog(@"Failed to delete record msg=%s", errMsg);
        return NO;
    }
    _messageCount = _messageCount - removeSize;
    return YES;
    
}

- (NSUInteger) count {
    return _messageCount;
}

- (NSInteger) sqliteCount {
    NSString *query = @"select count(*) from dataCache";
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
    NSString *query = @"VACUUM";
    char * errMsg;
    if (sqlite3_exec(_database, [query UTF8String] ,NULL,NULL,&errMsg) != SQLITE_OK) {
        NSLog(@"Failed to delete record msg=%s", errMsg);
        return @NO;
    }
    NSLog(@"vacuum success");
    return @YES;

}


@end
