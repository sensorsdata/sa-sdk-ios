//
// SAEventTrackerPluginManager.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/11/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAEventTrackerPluginManager.h"

@interface SAEventTrackerPluginManager ()

@property (nonatomic, strong) NSMutableArray<SAEventTrackerPlugin<SAEventTrackerPluginProtocol> *> *plugins;

@end

@implementation SAEventTrackerPluginManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static SAEventTrackerPluginManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAEventTrackerPluginManager alloc] init];
    });
    return manager;
}

- (void)registerPlugin:(SAEventTrackerPlugin<SAEventTrackerPluginProtocol> *)plugin {
    //object basic check, nil、class and protocol
    if (![plugin isKindOfClass:[SAEventTrackerPlugin class]] || ![plugin conformsToProtocol:@protocol(SAEventTrackerPluginProtocol)]) {
        return;
    }

    //required protocol implementation check
    if (![plugin respondsToSelector:@selector(install)] || ![plugin respondsToSelector:@selector(uninstall)]) {
        return;
    }

    //duplicate check
    if ([self.plugins containsObject:plugin]) {
        return;
    }

    //same type plugin check
    [self.plugins enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SAEventTrackerPlugin<SAEventTrackerPluginProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.type isEqualToString:plugin.type]) {
            [plugin uninstall];
            [self.plugins removeObject:obj];
            *stop = YES;
        }
    }];

    [self.plugins addObject:plugin];
    [plugin install];
}

- (void)unregisterPlugin:(Class)pluginClass {
    [self.plugins enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SAEventTrackerPlugin<SAEventTrackerPluginProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:pluginClass] && [obj respondsToSelector:@selector(uninstall)]) {
            [obj uninstall];
            [self.plugins removeObject:obj];
            *stop = YES;
        }
    }];
}

- (void)unregisterAllPlugins {
    [self.plugins enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SAEventTrackerPlugin<SAEventTrackerPluginProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(uninstall)]) {
            [obj uninstall];
            [self.plugins removeObject:obj];
        }
    }];
}

- (void)enableAllPlugins {
    for (SAEventTrackerPlugin<SAEventTrackerPluginProtocol> *plugin in self.plugins) {
        plugin.enable = YES;
    }
}

- (void)disableAllPlugins {
    for (SAEventTrackerPlugin<SAEventTrackerPluginProtocol> *plugin in self.plugins) {
        plugin.enable = NO;
    }
}

- (SAEventTrackerPlugin<SAEventTrackerPluginProtocol> *)pluginWithType:(NSString *)pluginType {
    for (SAEventTrackerPlugin<SAEventTrackerPluginProtocol> *plugin in self.plugins) {
        if ([plugin.type isEqualToString:pluginType]) {
            return plugin;
        }
    }
    return nil;
}

- (NSMutableArray<SAEventTrackerPlugin<SAEventTrackerPluginProtocol> *> *)plugins {
    if (!_plugins) {
        _plugins = [[NSMutableArray alloc] init];
    }
    return _plugins;
}

@end
