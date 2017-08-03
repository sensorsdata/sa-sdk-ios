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

static inline void SALog(NSString *format, ...) {
    __block va_list arg_list;
    va_start (arg_list, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    va_end(arg_list);
    NSLog(@"[SensorsAnalytics] %@", formattedString);
}

#if (defined DEBUG) || (defined SENSORS_ANALYTICS_ENABLE_LOG)
#define SAError(...) SALog(__VA_ARGS__)
#else
#define SAError(...)
#endif

#if (defined DEBUG) || (defined SENSORS_ANALYTICS_ENABLE_LOG)
#define SADebug(...) SALog(__VA_ARGS__)
#else
#define SADebug(...)
#endif

#endif /* defined(__SensorsAnalyticsSDK__SALogger__) */
