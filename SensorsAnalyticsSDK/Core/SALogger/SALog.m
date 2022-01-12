//
// SALog.m
// Logger
//
// Created by 陈玉国 on 2019/12/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
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

#import "SALog.h"
#import "SALog+Private.h"
#import "SALogMessage.h"
#import "SAAbstractLogger.h"
#import "SAConsoleLogger.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

@interface SALog ()

@property (nonatomic, strong) NSMutableArray <SAAbstractLogger <SALogger> *> *loggers;
@property (nonatomic, strong, readonly) NSDateFormatter *dateFormatter;

@end

@implementation SALog

static NSUInteger maxConcurrentCount;
static dispatch_queue_t logConcurrentQueue;
static dispatch_queue_t logSerialQueue;
static dispatch_semaphore_t logQueueSemaphore;
static dispatch_group_t logGroup;
static NSDateFormatter *dateFormatter;
static void *const GlobalLoggingQueueIdentityKey = (void *)&GlobalLoggingQueueIdentityKey;

+ (instancetype)sharedLog {
    static SALog *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        logConcurrentQueue = dispatch_queue_create("cn.sensorsdata.SALogConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);
        logSerialQueue = dispatch_queue_create("cn.sensorsdata.SALogSerialQueue", DISPATCH_QUEUE_SERIAL);
        logGroup = dispatch_group_create();
        void *nonNullValue = GlobalLoggingQueueIdentityKey;
        dispatch_queue_set_specific(logSerialQueue, GlobalLoggingQueueIdentityKey, nonNullValue, NULL);
        maxConcurrentCount = 10;
        logQueueSemaphore = dispatch_semaphore_create(maxConcurrentCount);
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSSSSSZ";
    });
    return sharedInstance;
}

+ (void)log:(BOOL)asynchronous level:(SALogLevel)level file:(const char *)file function:(const char *)function line:(NSUInteger)line context:(NSInteger)context format:(NSString *)format, ... {
    
    if (![SALog sharedLog].enableLog) {
        return;
    }

#if TARGET_OS_IOS
#ifndef DEBUG
    //in iOS10, initWithFormat: arguments: crashed when format string contain special char "%" but no escaped, like "%2434343%rfrfrfrf%".
    if ([[[UIDevice currentDevice] systemVersion] integerValue] == 10) {
        return;
    }
#endif
#endif

    if (!format) {
        return;
    }

    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [self log:asynchronous message:message level:level file:file function:function line:line context:context];
}

+ (void)log:(BOOL)asynchronous
    message:(NSString *)message
      level:(SALogLevel)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
    context:(NSInteger)context {
    [[self sharedLog] log:asynchronous message:message level:level file:file function:function line:line context:context];
}

+ (void)addLogger:(SAAbstractLogger<SALogger> *)logger {
    [[self sharedLog] addLogger:logger];
}

+ (void)addLoggers:(NSArray<SAAbstractLogger<SALogger> *> *)loggers {
    [[self sharedLog] addLoggers:loggers];
}

+ (void)removeLogger:(SAAbstractLogger<SALogger> *)logger {
    [[self sharedLog] removeLogger:logger];
}

+ (void)removeLoggers:(NSArray<SAAbstractLogger<SALogger> *> *)loggers {
    [[self sharedLog] removeLoggers:loggers];
}

+ (void)removeAllLoggers {
    [[self sharedLog] removeAllLoggers];
}

- (void)log:(BOOL)asynchronous level:(SALogLevel)level file:(const char *)file function:(const char *)function line:(NSUInteger)line context:(NSInteger)context format:(NSString *)format, ... {
    
    if (!self.enableLog) {
        return;
    }

#if TARGET_OS_IOS
#ifndef DEBUG
    //in iOS10, initWithFormat: arguments: crashed when format string contain special char "%" but no escaped, like "%2434343%rfrfrfrf%".
    if ([[[UIDevice currentDevice] systemVersion] integerValue] == 10) {
        return;
    }
#endif
#endif

    if (!format) {
        return;
    }

    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [self log:asynchronous message:message level:level file:file function:function line:line context:context];
}

- (void)log:(BOOL)asynchronous
    message:(NSString *)message
      level:(SALogLevel)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
    context:(NSInteger)context {
    if (file == NULL || function == NULL) {
        return;
    }
    NSDate *timestamp = [NSDate date];
    SALogMessage *logMessage = [[SALogMessage alloc] initWithMessage:message level:level file:[NSString stringWithUTF8String:file] function:[NSString stringWithUTF8String:function] line:line context:context timestamp:timestamp];
    [self queueLogMessage:logMessage asynchronously:asynchronous];
}

- (void)queueLogMessage:(SALogMessage *)logMessage asynchronously:(BOOL)asyncFlag {
    dispatch_block_t logBlock = ^{
        dispatch_semaphore_wait(logQueueSemaphore, DISPATCH_TIME_FOREVER);
        @autoreleasepool {
            [self log:logMessage];
        }
    };

    if (asyncFlag) {
        dispatch_async(logSerialQueue, logBlock);
    } else if (dispatch_get_specific(GlobalLoggingQueueIdentityKey)) {
        logBlock();
    } else {
        dispatch_sync(logSerialQueue, logBlock);
    }
}

- (void)log:(SALogMessage *)logMessage {
    for (SAAbstractLogger<SALogger> *logger in self.loggers) {
        dispatch_group_async(logGroup, logger.loggerQueue, ^{
            @autoreleasepool {
                [logger logMessage:logMessage];
            }
        });
        dispatch_group_wait(logGroup, DISPATCH_TIME_FOREVER);
    }
    dispatch_semaphore_signal(logQueueSemaphore);
}

- (void)addLogger:(SAAbstractLogger<SALogger> *)logger {
    if ([self.loggers containsObject:logger]) {
        return;
    }
    [self.loggers addObject:logger];
}

- (void)addLoggers:(NSArray<SAAbstractLogger<SALogger> *> *)loggers {
    [self.loggers addObjectsFromArray:loggers];
    NSOrderedSet *loggerSet = [NSOrderedSet orderedSetWithArray:self.loggers];
    self.loggers = [NSMutableArray arrayWithArray:[loggerSet array]];
}

- (void)removeLogger:(SAAbstractLogger<SALogger> *)logger {
    [self.loggers removeObject:logger];
}

- (void)removeLoggers:(NSArray<SAAbstractLogger<SALogger> *> *)loggers {
    [self.loggers removeObjectsInArray:loggers];
}

- (void)removeAllLoggers {
    [self.loggers removeAllObjects];
}

- (NSMutableArray<SAAbstractLogger<SALogger> *> *)loggers {
    if (!_loggers) {
        _loggers = [[NSMutableArray alloc] init];
    }
    return _loggers;
}

- (NSDateFormatter *)dateFormatter {
    return dateFormatter;
}

@end
