//
// SAExposureData.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAExposureConfig.h"
#import "SAExposureListener.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAExposureData : NSObject

@property (nonatomic, copy, readonly) NSString *event;
@property (nonatomic, copy, readonly) NSString *exposureIdentifier;
@property (nonatomic, copy, readonly) SAExposureConfig *config;
@property (nonatomic, weak) id<SAExposureListener> exposureListener;

- (instancetype)init NS_UNAVAILABLE;

/// init method
/// @param event event name
- (instancetype)initWithEvent:(NSString *)event;

/// init method
/// @param event event name
/// @param properties custom event properties, if no, use nil
- (instancetype)initWithEvent:(NSString *)event properties:(nullable NSDictionary *)properties;

/// init method
/// @param event event name
/// @param properties custom event properties, if no, use nil
/// @param exposureIdentifier identifier for view
- (instancetype)initWithEvent:(NSString *)event properties:(nullable NSDictionary *)properties exposureIdentifier:(nullable NSString *)exposureIdentifier;

/// init method
/// @param event event name
/// @param properties custom event properties, if no, use nil
/// @param config exposure config, if nil, use global config in SAConfigOptions
- (instancetype)initWithEvent:(NSString *)event properties:(nullable NSDictionary *)properties config:(nullable SAExposureConfig *)config;

/// init method
/// @param event event name
/// @param properties custom event properties, if no, use nil
/// @param exposureIdentifier identifier for view
/// @param config exposure config, if nil, use global config in SAConfigOptions
- (instancetype)initWithEvent:(NSString *)event properties:(nullable NSDictionary *)properties exposureIdentifier:(nullable NSString *)exposureIdentifier config:(nullable SAExposureConfig *)config;

@end

NS_ASSUME_NONNULL_END
