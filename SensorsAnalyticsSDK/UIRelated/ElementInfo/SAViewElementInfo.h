//
// SAViewElementInfo.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAViewElementInfo : NSObject

@property (nonatomic, weak) UIView *view;

- (instancetype)initWithView:(UIView *)view;

- (NSString *)elementType;

- (BOOL)isSupportElementPosition;

@end

@interface SAAlertElementInfo : SAViewElementInfo
@end

@interface SAMenuElementInfo : SAViewElementInfo
@end

NS_ASSUME_NONNULL_END
