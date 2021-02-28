//
//  SAConsoleLogger.m
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
    
    NSError *error = nil;
    NSPropertyListFormat format = NSPropertyListOpenStepFormat;
    NSString *formatString = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:&error];
    return error ? self : [formatString stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\n"];
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
