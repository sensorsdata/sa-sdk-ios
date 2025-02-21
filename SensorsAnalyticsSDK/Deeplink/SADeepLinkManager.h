//
// SADeepLinkManager.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/1/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAConfigOptions.h"
#import "SAModuleProtocol.h"
#import "SADeepLinkProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (DeepLinkPrivate)

@property (nonatomic, assign) BOOL enableDeepLink;

@end

@interface SADeepLinkManager : NSObject <SAModuleProtocol, SAOpenURLProtocol, SADeepLinkModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) SAConfigOptions *configOptions;

@property (nonatomic, copy) SADeepLinkCompletion oldCompletion;
@property (nonatomic, copy) SADeepLinkCompletion completion;

- (void)trackDeepLinkLaunchWithURL:(NSString *)url;

- (void)requestDeferredDeepLink:(NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
