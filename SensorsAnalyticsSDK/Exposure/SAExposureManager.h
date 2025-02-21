//
// SAExposureManager.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAConfigOptions.h"
#import "SAModuleProtocol.h"
#import "SAExposureViewObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAExposureManager : NSObject <SAModuleProtocol>

- (instancetype)init NS_UNAVAILABLE;

/// singleton instance
+ (instancetype)defaultManager;

@property (nonatomic, strong) SAConfigOptions *configOptions;
@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) NSMutableArray<SAExposureViewObject *> *exposureViewObjects;

- (void)addExposureView:(UIView *)view withData:(SAExposureData *)data;
- (void)removeExposureView:(UIView *)view withExposureIdentifier:(nullable NSString *)identifier;

- (SAExposureViewObject *)exposureViewWithView:(UIView *)view;

/// update properties for certain view that need to expose
/// - Parameters:
///   - view: view to expose
///   - properties: properties to update
- (void)updateExposure:(UIView *)view withProperties:(NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
