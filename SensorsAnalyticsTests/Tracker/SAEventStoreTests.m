//
// SAEventStoreTests.m
// SensorsAnalyticsTests
//
// Created by 张敏超🍎 on 2020/7/1.
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
#import "SAObject+SAConfigOptions.h"
#import "SAEventStore.h"

@interface SAEventStoreTests : XCTestCase
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) SAEventStore *eventStore;
@end

@implementation SAEventStoreTests

- (void)setUp {
    NSString *fileName = [NSString stringWithFormat:@"test_%d.db", arc4random()];
    self.filePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
    self.eventStore = [[SAEventStore alloc] initWithFilePath:self.filePath];
}

- (void)tearDown {
    self.eventStore = nil;

    [NSFileManager.defaultManager removeItemAtPath:self.filePath error:nil];
    self.filePath = nil;
}

- (void)insertHundredRecords {
    for (int index = 0; index < 100; index++) {
        SAEventRecord *record = [[SAEventRecord alloc] initWithRecordID:@"1" content:[NSString stringWithFormat:@"{\"index\":%d}", index]];
        record.type = @"POST";
        [self.eventStore insertRecord:record];
    }
}

- (void)testInsertRecordsWithHundredRecords {
    [self insertHundredRecords];
    XCTAssertEqual(self.eventStore.count, 100);
}

- (void)testInsertRecordWithRecord {
    SAEventRecord *record = [[SAEventRecord alloc] initWithRecordID:@"1" content:@"{\"index\":\"1\"}"];
    BOOL success = [self.eventStore insertRecord:record];
    XCTAssertTrue(success);
    XCTAssertEqual(self.eventStore.count, 1);
}

- (void)testSelsctRecordsWith50Record {
    [self insertHundredRecords];

    NSArray<SAEventRecord *> *records = [self.eventStore selectRecords:50];
    XCTAssertEqual(records.count, 50);
}

- (void)testDeleteRecords {
    [self insertHundredRecords];

    NSArray<SAEventRecord *> *records = [self.eventStore selectRecords:50];
    NSMutableArray *recordIDs = [NSMutableArray arrayWithCapacity:50];
    for (SAEventRecord *record in records) {
        [recordIDs addObject:record.recordID];
    }
    [self.eventStore deleteRecords:recordIDs];
    XCTAssertEqual(self.eventStore.count, 50);
}

- (void)testDeleteAllRecords {
    [self insertHundredRecords];
    BOOL success = [self.eventStore deleteAllRecords];
    XCTAssertTrue(success);
    XCTAssertEqual(self.eventStore.count, 0);
}

#pragma mark -

- (void)insertHundredRecordsWithEventStore:(SAEventStore *)store {
    for (int index = 0; index < 100; index++) {
        SAEventRecord *record = [[SAEventRecord alloc] initWithRecordID:@"1" content:[NSString stringWithFormat:@"{\"index\":%d}", index]];
        record.type = @"POST";
        [store insertRecord:record];
    }
}

- (void)testInsertHundredRecordsWithoutDatabase {
    SAEventStore *store = [[SAEventStore alloc] initWithFilePath:@"/sss/sdfa99qwedjfjdnv(ajs;./"];
    [self insertHundredRecordsWithEventStore:store];
    XCTAssertEqual(store.count, 100);
}

- (void)testSelsctRecordsWithoutDatabase {
    SAEventStore *store = [[SAEventStore alloc] initWithFilePath:@"/sss/sdfa99qwedjfjdnv(ajs;./"];
    [self insertHundredRecordsWithEventStore:store];

    NSArray<SAEventRecord *> *records = [store selectRecords:50];
    XCTAssertEqual(records.count, 50);
}

- (void)testDeleteRecordsWithoutDatabase {
    SAEventStore *store = [[SAEventStore alloc] initWithFilePath:@"/sss/sdfa99qwedjfjdnv(ajs;./"];
    [self insertHundredRecordsWithEventStore:store];

    NSArray<SAEventRecord *> *records = [store selectRecords:50];
    NSMutableArray *recordIDs = [NSMutableArray arrayWithCapacity:50];
    for (SAEventRecord *record in records) {
        [recordIDs addObject:record.recordID];
    }
    [store deleteRecords:recordIDs];
    XCTAssertEqual(store.count, 50);
}

- (void)testDeleteAllRecordsWithoutDatabase {
    SAEventStore *store = [[SAEventStore alloc] initWithFilePath:@"/sss/sdfa99qwedjfjdnv(ajs;./"];
    [self insertHundredRecordsWithEventStore:store];

    BOOL success = [store deleteAllRecords];
    XCTAssertTrue(success);
    XCTAssertEqual(store.count, 0);
}

@end
