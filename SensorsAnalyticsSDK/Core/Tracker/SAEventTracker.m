//
// SAEventTracker.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/6/18.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAEventTracker.h"
#import "SAEventFlush.h"
#import "SAEventStore.h"
#import "SADatabase.h"
#import "SANetwork.h"
#import "SAFileStore.h"
#import "SAJSONUtil.h"
#import "SALog.h"
#import "SAObject+SAConfigOptions.h"
#import "SAReachability.h"
#import "SAConstants+Private.h"
#import "SAModuleManager.h"

static NSInteger kSAFlushMaxRepeatCount = 100;

@interface SAEventTracker ()

@property (nonatomic, strong) SAEventStore *eventStore;

@property (nonatomic, strong) SAEventFlush *eventFlush;

@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation SAEventTracker

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;

        dispatch_async(self.queue, ^{
            self.eventStore = [[SAEventStore alloc] initWithFilePath:[SAFileStore filePath:@"message-v2"]];
            self.eventFlush = [[SAEventFlush alloc] init];
        });
    }
    return self;
}

- (void)trackEvent:(NSDictionary *)event {
    [self trackEvent:event isSignUp:NO];
}

/// 事件入库
/// ⚠️ 注意: SF 和 A/B Testing 会 Hook 该方法修改 distinct_id, 因此该方法不能被修改
/// @param event 事件信息
/// @param isSignUp 是否是用户关联事件, 用户关联事件会触发 flush
- (void)trackEvent:(NSDictionary *)event isSignUp:(BOOL)isSignUp {
    SAEventRecord *record = [[SAEventRecord alloc] initWithEvent:event type:@"POST"];
    // 尝试加密
    NSDictionary *obj = [SAModuleManager.sharedInstance encryptJSONObject:record.event];
    [record setSecretObject:obj];

    [self.eventStore insertRecord:record];

    // $SignUp 事件或者本地缓存的数据是超过 flushBulkSize
    if (isSignUp || self.eventStore.count > self.flushBulkSize || self.isDebugMode) {
        // 添加异步队列任务，保证数据继续入库
        dispatch_async(self.queue, ^{
            [self flushAllEventRecords];
        });
    }
}

- (BOOL)canFlush {
    // serverURL 是否有效
    if (self.eventFlush.serverURL.absoluteString.length == 0) {
        return NO;
    }
    // 判断当前网络类型是否符合同步数据的网络策略
    if (!([SANetwork networkTypeOptions] & self.networkTypePolicy)) {
        return NO;
    }
    return YES;
}

/// 筛选加密数据，并对未加密的数据尝试加密
/// 即使未开启加密，也可以进行筛选，可能存在加密开关的情况
/// @param records 数据
- (NSArray<SAEventRecord *> *)encryptEventRecords:(NSArray<SAEventRecord *> *)records {
    NSMutableArray *encryptRecords = [NSMutableArray arrayWithCapacity:records.count];
    for (SAEventRecord *record in records) {
        if (record.isEncrypted) {
            [encryptRecords addObject:record];
        } else {
            // 缓存数据未加密，再加密
            NSDictionary *obj = [SAModuleManager.sharedInstance encryptJSONObject:record.event];
            if (obj) {
                [record setSecretObject:obj];
                [encryptRecords addObject:record];
            }
        }
    }
    return encryptRecords.count == 0 ? records : encryptRecords;
}

- (void)flushAllEventRecords {
    [self flushAllEventRecordsWithCompletion:nil];
}

- (void)flushAllEventRecordsWithCompletion:(void(^)(void))completion {
    if (![self canFlush]) {
        if (completion) {
            completion();
        }
        return;
    }
    [self flushRecordsWithSize:self.isDebugMode ? 1 : 50 repeatCount:kSAFlushMaxRepeatCount completion:completion];
}

- (void)flushRecordsWithSize:(NSUInteger)size repeatCount:(NSInteger)repeatCount completion:(void(^)(void))completion {
    // 防止在数据量过大时, 递归 flush, 导致堆栈溢出崩溃; 因此需要限制递归次数
    if (repeatCount <= 0) {
        if (completion) {
            completion();
        }
        return;
    }
    // 从数据库中查询数据
    NSArray<SAEventRecord *> *records = [self.eventStore selectRecords:size];
    if (records.count == 0) {
        if (completion) {
            completion();
        }
        return;
    }

    // 尝试加密，筛选加密数据
    NSArray<SAEventRecord *> *encryptRecords = [self encryptEventRecords:records];

    // 获取查询到的数据的 id
    NSMutableArray *recordIDs = [NSMutableArray arrayWithCapacity:encryptRecords.count];
    for (SAEventRecord *record in encryptRecords) {
        [recordIDs addObject:record.recordID];
    }

    // 更新数据状态
    [self.eventStore updateRecords:recordIDs status:SAEventRecordStatusFlush];

    // flush
    __weak typeof(self) weakSelf = self;
    [self.eventFlush flushEventRecords:encryptRecords completion:^(BOOL success) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        void(^block)(void) = ^ {
            if (!success) {
                [strongSelf.eventStore updateRecords:recordIDs status:SAEventRecordStatusNone];
                if (completion) {
                    completion();
                }
                return;
            }
            // 5. 删除数据
            if ([strongSelf.eventStore deleteRecords:recordIDs]) {
                [strongSelf flushRecordsWithSize:size repeatCount:repeatCount - 1 completion:completion];
            }
        };
        if (sensorsdata_is_same_queue(strongSelf.queue)) {
            block();
        } else {
            dispatch_sync(strongSelf.queue, block);
        }
    }];
}

@end
