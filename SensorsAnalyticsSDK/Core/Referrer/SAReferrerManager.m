//
// SAReferrerManager.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/12/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAReferrerManager.h"
#import "SAConstants+Private.h"

@interface SAReferrerManager ()

@property (atomic, copy) NSDictionary *referrerProperties;
@property (atomic, copy) NSString *referrerURL;
@property (nonatomic, copy) NSString *referrerTitle;
@property (nonatomic, copy) NSString *currentTitle;
@property (atomic, copy) NSString *currentScreenUrl;
@property (nonatomic, copy) NSDictionary *currentScreenProperties;

@end

@implementation SAReferrerManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAReferrerManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAReferrerManager alloc] init];
    });
    return manager;
}

- (NSDictionary *)propertiesWithURL:(NSString *)currentURL eventProperties:(NSDictionary *)eventProperties {
    self.referrerURL = self.currentScreenUrl;
    self.referrerProperties = self.currentScreenProperties;
    NSMutableDictionary *newProperties = [NSMutableDictionary dictionaryWithDictionary:eventProperties];

    // 客户自定义属性中包含 $url 时，以客户自定义内容为准
    if (!newProperties[kSAEventPropertyScreenUrl]) {
        newProperties[kSAEventPropertyScreenUrl] = currentURL;
    }
    // 客户自定义属性中包含 $referrer 时，以客户自定义内容为准
    if (self.referrerURL && !newProperties[kSAEventPropertyScreenReferrerUrl]) {
        newProperties[kSAEventPropertyScreenReferrerUrl] = self.referrerURL;
    }

    NSMutableDictionary *lastScreenProperties = [NSMutableDictionary dictionaryWithDictionary:newProperties];
    [lastScreenProperties removeObjectForKey:kSAEventPropertyScreenReferrerUrl];
    self.currentScreenProperties = [lastScreenProperties copy];
    self.currentScreenUrl = newProperties[kSAEventPropertyScreenUrl];
    dispatch_async(self.serialQueue, ^{
        [self cacheReferrerTitle:newProperties];
    });
    return newProperties;
}

- (void)cacheReferrerTitle:(NSDictionary *)properties {
    self.referrerTitle = self.currentTitle;
    self.currentTitle = properties[kSAEventPropertyTitle];
}

- (void)clearReferrer {
    if (self.isClearReferrer) {
        // 需求层面只需要清除 $referrer，不需要清除 $referrer_title
        self.referrerURL = nil;
    }
}

@end
