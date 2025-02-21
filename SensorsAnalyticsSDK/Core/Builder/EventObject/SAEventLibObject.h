//
// SAEventLibObject.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

/// SDK 类型
extern NSString * const kSAEventPresetPropertyLib;
/// SDK 方法
extern NSString * const kSAEventPresetPropertyLibMethod;
/// SDK 版本
extern NSString * const kSAEventPresetPropertyLibVersion;
/// SDK 调用栈
extern NSString * const kSAEventPresetPropertyLibDetail;
/// 应用版本
extern NSString * const kSAEventPresetPropertyAppVersion;

@interface SAEventLibObject : NSObject <SAPropertyPluginLibFilter>

@property (nonatomic, copy) NSString *lib;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, strong) id appVersion;
@property (nonatomic, copy, nullable) NSString *detail;

- (NSMutableDictionary *)jsonObject;

- (instancetype)initWithH5Lib:(NSDictionary *)lib;

@end

NS_ASSUME_NONNULL_END
