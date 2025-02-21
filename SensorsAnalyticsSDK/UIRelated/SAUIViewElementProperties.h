//
// SAUIViewElementProperties.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SAUIViewElementProperties <NSObject>

@optional
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementType;
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementContent;
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementId;
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementPosition;

@end

NS_ASSUME_NONNULL_END
