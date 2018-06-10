//
//  SALogger.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/6.
//  Copyright (c) 2015年 SensorsData. All rights reserved.
//
#import <UIKit/UIKit.h>
#ifndef __SensorsAnalyticsSDK__SALogger__
#define __SensorsAnalyticsSDK__SALogger__

#define SALogLevel(lvl,fmt,...)\
[SALogger log : YES                                      \
level : lvl                                                  \
file : __FILE__                                            \
function : __PRETTY_FUNCTION__                       \
line : __LINE__                                           \
format : (fmt), ## __VA_ARGS__]

#define SALog(fmt,...)\
SALogLevel(SALoggerLevelInfo,(fmt), ## __VA_ARGS__)

#define SAError SALog
#define SADebug SALog

#endif/* defined(__SensorsAnalyticsSDK__SALogger__) */
typedef NS_ENUM(NSUInteger,SALoggerLevel){
    SALoggerLevelInfo = 1,
    SALoggerLevelWarning ,
    SALoggerLevelError ,
};

@interface SALogger:NSObject
@property(class , readonly, strong) SALogger *sharedInstance;
+ (BOOL)isLoggerEnabled;
+ (void)enableLog:(BOOL)enableLog;
+ (void)log:(BOOL)asynchronous
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
     format:(NSString *)format, ... ;
@end
