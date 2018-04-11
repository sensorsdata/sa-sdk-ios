//
//  SALogger.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/3/28.
//  Copyright © 2018年 SensorsData. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "SALogger.h"
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
    dispatch_sync(__logQueue__, ^{
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
    @try{
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        [self.sharedInstance log:asynchronous message:message level:level file:file function:function line:line];
        va_end(args);
    } @catch(NSException *e){
       
    }
}

- (void)log:(BOOL)asynchronous
    message:(NSString *)message
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line {
    @try{
        NSString *logMessage = [[NSString alloc]initWithFormat:@"[SALog][%@]  %s [line %lu]    %s %@",[self descriptionForLevel:level],function,(unsigned long)line,[@"" UTF8String],message];
        if (__enableLog__) {
            NSLog(@"%@",logMessage);
        }
    } @catch(NSException *e){
       
    }
}

-(NSString *)descriptionForLevel:(SALoggerLevel)level {
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
