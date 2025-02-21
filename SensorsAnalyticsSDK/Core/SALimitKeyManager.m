//
// SALimitKeyManager.m
// SensorsAnalyticsSDK
//
// Created by MC on 2022/10/20.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SALimitKeyManager.h"
#import "SAConstants.h"

@interface SALimitKeyManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *keys;

@end

@implementation SALimitKeyManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _keys = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SALimitKeyManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SALimitKeyManager alloc] init];
    });
    return manager;
}

+ (void)registerLimitKeys:(NSDictionary<SALimitKey, NSString *> *)keys {
    if (![keys isKindOfClass:[NSDictionary class]]) {
        return;
    }
    [[SALimitKeyManager sharedInstance].keys addEntriesFromDictionary:[keys copy]];
}

+ (NSString *)idfa {
    return [SALimitKeyManager sharedInstance].keys[SALimitKeyIDFA];
}

+ (NSString *)idfv {
    return [SALimitKeyManager sharedInstance].keys[SALimitKeyIDFV];
}
@end
