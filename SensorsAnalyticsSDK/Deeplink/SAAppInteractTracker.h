//
// SAAppInteractTracker.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/10/23.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAAppInteractTracker : NSObject

@property (nonatomic, assign) BOOL awakeFromDeeplink;
@property (nonatomic, copy) NSString *wakeupUrl;

@end

NS_ASSUME_NONNULL_END
