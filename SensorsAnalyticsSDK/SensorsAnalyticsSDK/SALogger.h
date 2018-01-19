//
//  SALogger.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/6.
//  Copyright (c) 2015年 SensorsData. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SensorsAnalyticsSDK.h"
#ifndef __SensorsAnalyticsSDK__SALogger__
#define __SensorsAnalyticsSDK__SALogger__

static inline void SALog(NSString *format, ...) {
    BOOL printLog = NO;
#if (defined SENSORS_ANALYTICS_ENABLE_LOG)
    printLog = YES;
#endif

#if (defined SENSORS_ANALYTICS_DISABLE_LOG)
    printLog = NO;
#endif

    if ([[SensorsAnalyticsSDK sharedInstance] debugMode] != SensorsAnalyticsDebugOff) {
        printLog = YES;
    }

    if (printLog) {
        __block va_list arg_list;
        va_start (arg_list, format);
        NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
        va_end(arg_list);
        NSLog(@"[SensorsAnalytics] %@", formattedString);
    }
}

#define SAError(...) SALog(__VA_ARGS__)

#define SADebug(...) SALog(__VA_ARGS__)

#endif /* defined(__SensorsAnalyticsSDK__SALogger__) */
