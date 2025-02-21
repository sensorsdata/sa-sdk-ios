//
// SAUIViewPathProperties.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SAUIViewPathProperties <NSObject>

@optional
@property (nonatomic, copy, readonly) NSString *sensorsdata_itemPath;
@property (nonatomic, copy, readonly) NSString *sensorsdata_similarPath;
@property (nonatomic, copy, readonly) NSIndexPath *sensorsdata_IndexPath;
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementPath;

@end

NS_ASSUME_NONNULL_END
