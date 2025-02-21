//
// SAEncryptManager.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/11/25.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAEncryptManager : NSObject <SAModuleProtocol, SAOpenURLProtocol, SAEncryptModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) SAConfigOptions *configOptions;

- (NSDictionary *)encryptEventRecord:(NSDictionary *)eventRecord;
- (NSDictionary *)decryptEventRecord:(NSDictionary *)eventRecord;

@end

NS_ASSUME_NONNULL_END
