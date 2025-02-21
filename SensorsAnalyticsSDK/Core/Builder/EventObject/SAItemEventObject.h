//
// SAItemEventObject.h
// SensorsAnalyticsSDK
//
// Created by 张敏超 on 2021/11/3.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SABaseEventObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAItemEventObject : SABaseEventObject

@property (nonatomic, copy, nullable) NSString *itemType;
@property (nonatomic, copy, nullable) NSString *itemID;

- (instancetype)initWithType:(NSString *)type itemType:(NSString *)itemType itemID:(NSString *)itemID;

@end

NS_ASSUME_NONNULL_END
