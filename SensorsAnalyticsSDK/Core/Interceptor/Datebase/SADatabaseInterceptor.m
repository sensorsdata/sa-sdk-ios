//
// SADatabaseInterceptor.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/17.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
