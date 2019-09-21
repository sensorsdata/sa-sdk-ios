//
//  SALogger.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/6.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
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
typedef NS_ENUM(NSUInteger, SALoggerLevel) {
    SALoggerLevelInfo = 1,
    SALoggerLevelWarning,
    SALoggerLevelError,
};

@interface SALogger : NSObject
#ifdef UIKIT_DEFINE_AS_PROPERTIES
@property (class , readonly, strong) SALogger *sharedInstance;
#else
+ (SALogger *)sharedInstance;
#endif
+ (BOOL)isLoggerEnabled;
+ (void)enableLog:(BOOL)enableLog;
+ (void)log:(BOOL)asynchronous
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
     format:(NSString *)format, ... ;

- (void)log:(BOOL)asynchronous
    message:(NSString *)message
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line;

@end
