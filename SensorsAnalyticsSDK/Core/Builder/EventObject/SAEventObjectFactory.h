//
// SAEventObjectFactory.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SABaseEventObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAEventObjectFactory : NSObject

+ (SABaseEventObject *)eventObjectWithH5Event:(NSDictionary *)event;

@end

NS_ASSUME_NONNULL_END
