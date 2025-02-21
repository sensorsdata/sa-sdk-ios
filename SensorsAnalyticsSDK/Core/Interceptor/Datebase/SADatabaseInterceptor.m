//
// SADatabaseInterceptor.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/17.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SADatabaseInterceptor.h"
#import "SAFileStorePlugin.h"
#import "SAFlowManager.h"

@interface SADatabaseInterceptor()

@property (nonatomic, strong, readwrite) SAEventStore *eventStore;

@end

@implementation SADatabaseInterceptor

+ (instancetype)interceptorWithParam:(NSDictionary *)param {
    SADatabaseInterceptor *interceptor = [super interceptorWithParam:param];
    NSString *fileName = param[kSADatabaseNameKey] ?: kSADatabaseDefaultFileName;
    NSString *filePath = [SAFileStorePlugin filePath:fileName];

#if TARGET_OS_OSX
    NSString *databaseFilePath = SAFlowManager.sharedInstance.configOptions.databaseFilePath;
    if (databaseFilePath && [databaseFilePath hasSuffix: @".plist"]) {
        filePath = databaseFilePath;
    }
#endif
    
    interceptor.eventStore = [SAEventStore eventStoreWithFilePath:filePath];

    return interceptor;
}


@end
