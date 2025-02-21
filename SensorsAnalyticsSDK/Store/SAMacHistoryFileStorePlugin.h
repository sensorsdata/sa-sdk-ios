//
// SAMacHistoryFileStorePlugin.h
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2024/9/2.
// Copyright © 2015-2024 Sensors Data Co., Ltd. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "SAStorePlugin.h"


NS_ASSUME_NONNULL_BEGIN

// macOS 历史文件迁移
@interface SAMacHistoryFileStorePlugin : NSObject<SAStorePlugin>


+ (NSString *)filePath:(NSString *)key;

- (NSArray *)storeKeys;

@end

NS_ASSUME_NONNULL_END
