//
// SAFileStorePlugin.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/12/1.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAStorePlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAFileStorePlugin : NSObject <SAStorePlugin>

+ (NSString *)filePath:(NSString *)key;

- (NSArray *)storeKeys;

@end

NS_ASSUME_NONNULL_END
