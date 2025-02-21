//
// SAViewElementInfoFactory.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SAViewElementInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAViewElementInfoFactory : NSObject

+ (SAViewElementInfo *)elementInfoWithView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
