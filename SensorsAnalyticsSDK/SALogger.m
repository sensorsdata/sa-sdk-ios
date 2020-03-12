//
//  SALogger.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/3/28.
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


#import <Foundation/Foundation.h>
#import "SALogger.h"

#pragma mark -
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


#pragma mark - SALogger
static BOOL __enableLog__ ;
static dispatch_queue_t __logQueue__ ;
@implementation SALogger
+ (void)initialize {
    __enableLog__ = NO;
    __logQueue__ = dispatch_queue_create("com.sensorsdata.analytics.log", DISPATCH_QUEUE_SERIAL);
}

+ (BOOL)isLoggerEnabled {
    __block BOOL enable = NO;
    dispatch_sync(__logQueue__, ^{
        enable = __enableLog__;
    });
    return enable;
}

+ (void)enableLog:(BOOL)enableLog {
    dispatch_async(__logQueue__, ^{
        __enableLog__ = enableLog;
    });
}

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void)log:(BOOL)asynchronous
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
     format:(NSString *)format, ... {
    if (![SALogger isLoggerEnabled]) {
        return;
    }
    
    //iOS 10.x 有可能触发 [[NSString alloc] initWithFormat:format arguments:args]  crash ，不在启用 Log
#ifndef DEBUG
    NSInteger systemVersion = UIDevice.currentDevice.systemVersion.integerValue;
    if (systemVersion == 10) {
        return;
    }
#endif
    @try {
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        [self.sharedInstance log:asynchronous message:message level:level file:file function:function line:line];
        va_end(args);
    } @catch(NSException *e) {
       
    }
}

- (void)log:(BOOL)asynchronous
    message:(NSString *)message
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line {
    @try {
        dispatch_async(__logQueue__ , ^{
            NSString *logMessage = [[NSString alloc] initWithFormat:@"[SALog][%@]  %s [line %lu]    %s %@", [self descriptionForLevel:level], function, (unsigned long)line, [@"" UTF8String], message.sensorsdata_unicodeString];
            NSLog(@"%@", logMessage);
        });
    } @catch(NSException *e) {
       
    }
}

- (NSString *)descriptionForLevel:(SALoggerLevel)level {
    NSString *desc = nil;
    switch (level) {
        case SALoggerLevelInfo:
            desc = @"INFO";
            break;
        case SALoggerLevelWarning:
            desc = @"WARN";
            break;
        case SALoggerLevelError:
            desc = @"ERROR";
            break;
        default:
            desc = @"UNKNOW";
            break;
    }
    return desc;
}

- (void)dealloc {
    
}

@end
