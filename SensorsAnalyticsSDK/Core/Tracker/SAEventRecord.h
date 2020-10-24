//
// SAEventRecord.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, SAEventRecordStatus) {
    SAEventRecordStatusNone,
    SAEventRecordStatusFlush,
};

@interface SAEventRecord : NSObject

@property (nonatomic, copy) NSString *recordID;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy, readonly) NSString *content;

@property (nonatomic) SAEventRecordStatus status;
@property (nonatomic, getter=isEncrypted) BOOL encrypted;

@property (nonatomic, copy, readonly) NSDictionary *event;

/// 通过 event 初始化方法
/// 主要是在 track 事件的时候使用
/// @param event 事件数据
/// @param type 上传数据类型
- (instancetype)initWithEvent:(NSDictionary *)event type:(NSString *)type;

/// 通过 recordID 和 content 进行初始化
/// 主要使用在从数据库中，获取数据时进行初始化
/// @param recordID 事件 id
/// @param content 事件 json 字符串数据
- (instancetype)initWithRecordID:(NSString *)recordID content:(NSString *)content;

- (instancetype)init NS_UNAVAILABLE;

- (BOOL)isValid;

- (void)addFlushTime;

@property (nonatomic, copy, readonly) NSString *ekey;

- (void)setSecretObject:(NSDictionary *)obj;

- (void)removePayload;
- (BOOL)mergeSameEKeyRecord:(SAEventRecord *)record;

@end

NS_ASSUME_NONNULL_END
