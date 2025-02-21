//
// SAExposureData.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAExposureData.h"
#import "NSDictionary+SACopyProperties.h"

@interface SAExposureData ()

@property (nonatomic, copy) NSString *event;
@property (nonatomic, copy) NSDictionary *properties;
@property (nonatomic, copy) NSString *exposureIdentifier;
@property (nonatomic, copy) SAExposureConfig *config;
@property (nonatomic, copy) NSDictionary *updatedProperties;

@end

@implementation SAExposureData

- (instancetype)initWithEvent:(NSString *)event {
    return [self initWithEvent:event properties:nil exposureIdentifier:nil config:nil];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    return [self initWithEvent:event properties:properties exposureIdentifier:nil config:nil];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties exposureIdentifier:(NSString *)exposureIdentifier {
    return [self initWithEvent:event properties:properties exposureIdentifier:exposureIdentifier config:nil];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties config:(SAExposureConfig *)config {
    return [self initWithEvent:event properties:properties exposureIdentifier:nil config:config];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties exposureIdentifier:(NSString *)exposureIdentifier config:(SAExposureConfig *)config {
    self = [super init];
    if (self) {
        _event = event;
        _properties = [properties sensorsdata_deepCopy];
        _exposureIdentifier = exposureIdentifier;
        _config = config;
    }
    return self;
}

- (void)setUpdatedProperties:(NSDictionary *)updatedProperties {
    _updatedProperties = [updatedProperties sensorsdata_deepCopy];
}
@end
