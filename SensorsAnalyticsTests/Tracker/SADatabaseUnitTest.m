//
// SADatabaseUnitTest.m
// SensorsAnalyticsTests
//
// Created by 陈玉国 on 2020/6/17.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import <XCTest/XCTest.h>
#import "SADatabase.h"
#import "SensorsAnalyticsSDK.h"

@interface SADatabaseUnitTest : XCTestCase

@property (nonatomic, strong) SADatabase *database;

@end

@implementation SADatabaseUnitTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.db"];
    self.database = [[SADatabase alloc] initWithFilePath:path];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.db"];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    self.database = nil;
}

- (void)testDBInstance {
    XCTAssertTrue(self.database != nil);
}

- (void)testDBOpen {
    XCTAssertTrue([self.database open]);
}

- (void)testDBCreateTable {
    XCTAssertTrue([self.database createTable]);
}

- (void)testInsertSingleRecord {
    NSString *content = @"testInsertSingleRecord";
    NSString *type = @"POST";
    SAEventRecord *record = [[SAEventRecord alloc] init];
    record.content = content;
    record.type = type;
    [self.database insertRecord:record];
    SAEventRecord *tempRecord = [self.database selectRecords:1].firstObject;
    XCTAssertTrue(tempRecord != nil && [tempRecord.content isEqualToString:content]);
}

- (void)testFetchRecord {
    NSString *content = @"testFetchRecord";
    NSString *type = @"POST";
    SAEventRecord *record = [[SAEventRecord alloc] init];
    record.content = content;
    record.type = type;
    [self.database insertRecord:record];
    SAEventRecord *tempRecord = [self.database selectRecords:1].firstObject;
    XCTAssertTrue(tempRecord != nil && [tempRecord.content isEqualToString:content]);
}

- (void)testDeleteRecords {
    NSMutableArray<SAEventRecord *> *tempRecords = [NSMutableArray array];
    for (NSUInteger index = 0; index < 10000; index++) {
        NSString *content = [NSString stringWithFormat:@"testDeleteRecords_%lu",index];
        NSString *type = @"POST";
        SAEventRecord *record = [[SAEventRecord alloc] init];
        record.content = content;
        record.type = type;
        [tempRecords addObject:record];
    }
    [self.database insertRecords:tempRecords];
    NSMutableArray <NSString *> *recordIDs = [NSMutableArray array];
    for (SAEventRecord *record in [self.database selectRecords:10000]) {
        [recordIDs addObject:record.recordID];
    }
    [self.database deleteRecords:recordIDs];
    XCTAssertTrue([self.database selectRecords:10000].count == 0);
}

- (void)testBulkInsertRecords {
    NSMutableArray<SAEventRecord *> *tempRecords = [NSMutableArray array];
    for (NSUInteger index = 0; index < 10000; index++) {
        NSString *content = [NSString stringWithFormat:@"testBulkInsertRecords_%lu",index];
        NSString *type = @"POST";
        SAEventRecord *record = [[SAEventRecord alloc] init];
        record.content = content;
        record.type = type;
        [tempRecords addObject:record];
    }
    [self.database insertRecords:tempRecords];
    NSArray<SAEventRecord *> *fetchRecords = [self.database selectRecords:10000];
    if (fetchRecords.count != 10000) {
        XCTAssertFalse(true);
        return;
    }
    BOOL success = YES;
    for (NSUInteger index; index < 10000; index++) {
        if (![fetchRecords[index].content isEqualToString:tempRecords[index].content]) {
            success = NO;
        }
    }
    XCTAssertTrue(success);
}

- (void)testDeleteAllRecords {
    NSMutableArray<SAEventRecord *> *tempRecords = [NSMutableArray array];
    for (NSUInteger index = 0; index < 10000; index++) {
        NSString *content = [NSString stringWithFormat:@"testDeleteAllRecords_%lu",index];
        NSString *type = @"POST";
        SAEventRecord *record = [[SAEventRecord alloc] init];
        record.content = content;
        record.type = type;
        [tempRecords addObject:record];
    }
    [self.database insertRecords:tempRecords];
    [self.database deleteAllRecords];
    XCTAssertTrue([self.database selectRecords:10000].count == 0);
}

@end
