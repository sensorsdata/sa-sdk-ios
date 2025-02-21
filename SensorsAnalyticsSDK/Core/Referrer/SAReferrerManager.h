//
// SAReferrerManager.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/12/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAReferrerManager : NSObject

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, assign) BOOL isClearReferrer;

@property (atomic, copy, readonly) NSDictionary *referrerProperties;
@property (atomic, copy, readonly) NSString *referrerURL;
@property (nonatomic, copy, readonly) NSString *referrerTitle;
@property (atomic, copy, readonly) NSString *currentScreenUrl;

+ (instancetype)sharedInstance;

- (NSDictionary *)propertiesWithURL:(NSString *)currentURL eventProperties:(NSDictionary *)eventProperties;

- (void)clearReferrer;

@end

NS_ASSUME_NONNULL_END
