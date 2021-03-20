//
//  SAFileLogger.m
//  Logger
//
//  Created by 陈玉国 on 2019/12/26.
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

#import "SAFileLogger.h"
#import "SALoggerConsoleFormatter.h"

@interface SAFileLogger ()

@property (nonatomic, copy) NSString *logFilePath;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) SALoggerConsoleFormatter *formatter;

@end

@implementation SAFileLogger

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileLogLevel = SALogLevelVerbose;
    }
    return self;
}

- (void)logMessage:(SALogMessage *)logMessage {
    [super logMessage:logMessage];
    if (logMessage.level > self.fileLogLevel) {
        return;
    }
    [self writeLogMessage:logMessage];
}

- (NSString *)logFilePath {
    if (!_logFilePath) {
        _logFilePath = [self currentlogFile];
    }
    return _logFilePath;
}

- (NSFileHandle *)fileHandle {
    if (!_fileHandle) {
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
    }
    return _fileHandle;
}

- (SALoggerConsoleFormatter *)formatter {
    if (!_formatter) {
        _formatter = [[SALoggerConsoleFormatter alloc] init];
    }
    return _formatter;
}

- (nullable NSString *)currentlogFile {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *logfilePath = [path stringByAppendingPathComponent:@"SALog/SALog.log"];
    BOOL fileExists = [manager fileExistsAtPath:logfilePath];
    if (fileExists) {
        return logfilePath;
    }
    NSError *error;
    BOOL directoryCreated = [manager createDirectoryAtPath:[logfilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
    if (!directoryCreated) {
        NSLog(@"SAFileLogger file directory created failed");
        return nil;
    }
    BOOL fileCreated = [[NSFileManager defaultManager] createFileAtPath:logfilePath contents:nil attributes:nil];
    if (!fileCreated) {
        NSLog(@"SAFileLogger file created failed");
        return nil;
    }
    return logfilePath;
}

- (void)writeLogMessage:(SALogMessage *)logMessage {
    if (!self.fileHandle) {
        return;
    }
    NSString *formattedMessage = [self.formatter formattedLogMessage:logMessage];
    @try {
        [self.fileHandle seekToEndOfFile];
        [self.fileHandle writeData:[formattedMessage dataUsingEncoding:NSUTF8StringEncoding]];
    } @catch (NSException *exception) {
        NSLog(@"SAFileLogger logMessage: %@", exception);
    } @finally {
        // any final action
    }
}

@end
