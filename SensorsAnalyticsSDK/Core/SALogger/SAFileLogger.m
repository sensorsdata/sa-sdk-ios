//
// SAFileLogger.m
// Logger
//
// Created by 陈玉国 on 2019/12/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
    NSDictionary *attributes = nil;
#if TARGET_OS_IOS || TARGET_OS_WATCH
    attributes = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
#endif
    BOOL fileCreated = [[NSFileManager defaultManager] createFileAtPath:logfilePath contents:nil attributes:attributes];
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
