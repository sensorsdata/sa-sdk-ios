//
// SAConsoleLogger.m
// Logger
//
// Created by 陈玉国 on 2019/12/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAConsoleLogger.h"
#import "SALoggerConsoleFormatter.h"
#import <sys/uio.h>


@interface NSString (Unicode)
@property (nonatomic, copy, readonly) NSString *sensorsdata_unicodeString;
@end

@implementation NSString (Unicode)

- (NSString *)sensorsdata_unicodeString {
    if ([self rangeOfString:@"\[uU][A-Fa-f0-9]{4}" options:NSRegularExpressionSearch].location == NSNotFound) {
        return self;
    }
    NSMutableString *mutableString = [NSMutableString stringWithString:self];
    [mutableString replaceOccurrencesOfString:@"\\u" withString:@"\\U" options:0 range:NSMakeRange(0, self.length)];
    [mutableString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, self.length)];
    [mutableString insertString:@"\"" atIndex:0];
    [mutableString appendString:@"\""];
    NSData *data = [mutableString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSPropertyListFormat format = NSPropertyListOpenStepFormat;
    NSString *formatString = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:NULL];
    return (!formatString || ![formatString isKindOfClass:NSString.class]) ? self : [formatString stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\n"];
}

@end

@implementation SAConsoleLogger

- (instancetype)init
{
    self = [super init];
    if (self) {
        _maxStackSize = 1024 * 4;
        self.loggerQueue = dispatch_queue_create("cn.sensorsdata.SAConsoleLoggerSerialQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)logMessage:(SALogMessage *)logMessage {
    [super logMessage:logMessage];
    
    SALoggerConsoleFormatter *formatter = [[SALoggerConsoleFormatter alloc] init];
    NSString *message = [formatter formattedLogMessage:logMessage].sensorsdata_unicodeString;
    NSUInteger messageLength = [message lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    BOOL useStack = messageLength < _maxStackSize;
    char messageStack[useStack ? (messageLength + 1) : 1];
    char *msg = useStack ? messageStack : (char *)calloc(messageLength + 1, sizeof(char));
    
    if (msg == NULL) {
        return;
    }
    
    BOOL canBeConvertedToEncoding = [message getCString:msg maxLength:(messageLength + 1) encoding:NSUTF8StringEncoding];
    
    if (!canBeConvertedToEncoding) {
        // free memory if not use stack
        if (!useStack) {
            free(msg);
        }
        return;
    }
    
    struct iovec dataBuffer[1];
    dataBuffer[0].iov_base = msg;
    dataBuffer[0].iov_len = messageLength;
    writev(STDERR_FILENO, dataBuffer, 1);
    
    // free memory if not use stack
    if (!useStack) {
        free(msg);
    }
    
}

@end
