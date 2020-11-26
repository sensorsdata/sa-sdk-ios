//
// SAModuleManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/8/14.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAModuleManager.h"
#import "SAModuleProtocol.h"

// Location 模块名
static NSString * const kSALocationModuleName = @"Location";
static NSString * const kSAChannelMatchModuleName = @"ChannelMatch";

@interface SAModuleManager ()

@property (atomic, strong) NSMutableDictionary<NSString *, id<SAModuleProtocol>> *modules;

@end

@implementation SAModuleManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAModuleManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAModuleManager alloc] init];
        manager.modules = [NSMutableDictionary dictionary];
    });
    return manager;
}

- (void)setEnable:(BOOL)enable forModule:(NSString *)moduleName {
    if (self.modules[moduleName]) {
        self.modules[moduleName].enable = enable;
    } else if (enable) {
        NSString *className = [NSString stringWithFormat:@"SA%@Manager", moduleName];
        Class<SAModuleProtocol> cla = NSClassFromString(className);
        NSAssert(cla, @"\n您使用接口开启了 %@ 模块，但是并没有集成该模块。\n • 如果使用源码集成神策分析 iOS SDK，请检查是否包含名为 %@ 的文件？\n • 如果使用 CocoaPods 集成 SDK，请修改 Podfile 文件，增加 %@ 模块的 subspec，例如：pod 'SensorsAnalyticsSDK', :subspecs => ['%@']。\n", moduleName, className, moduleName, moduleName);
        if ([cla conformsToProtocol:@protocol(SAModuleProtocol)]) {
            id<SAModuleProtocol> object = [[(Class)cla alloc] init];
            object.enable = enable;
            self.modules[moduleName] = object;
        }
    }
}

- (id<SAModuleProtocol>)managerForModuleType:(SAModuleType)type {
    NSString *name = [self moduleNameForType:type];
    return self.modules[name];
}

- (void)setEnable:(BOOL)enable forModuleType:(SAModuleType)type {
    NSString *name = [self moduleNameForType:type];
    [self setEnable:enable forModule:name];
}

- (NSString *)moduleNameForType:(SAModuleType)type {
    switch (type) {
        case SAModuleTypeLocation:
            return kSALocationModuleName;
        case SAModuleTypeChannelMatch:
            return kSAChannelMatchModuleName;
        default:
            return nil;
    }
}

#pragma mark - Open URL

- (BOOL)canHandleURL:(NSURL *)url {
    for (id<SAModuleProtocol> obj in self.modules.allValues) {
        if (![obj conformsToProtocol:@protocol(SAOpenURLProtocol)] || !obj.isEnable) {
            continue;
        }
        id<SAOpenURLProtocol> manager = (id<SAOpenURLProtocol>)obj;
        if ([manager canHandleURL:url]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)handleURL:(NSURL *)url {
    for (id<SAModuleProtocol> obj in self.modules.allValues) {
        if (![obj conformsToProtocol:@protocol(SAOpenURLProtocol)] || !obj.isEnable) {
            continue;
        }
        id<SAOpenURLProtocol> manager = (id<SAOpenURLProtocol>)obj;
        if ([manager canHandleURL:url]) {
            return [manager handleURL:url];
        }
    }
    return NO;
}

@end

#pragma mark -

@implementation SAModuleManager (Property)

- (NSDictionary *)properties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 兼容使用宏定义的方式源码集成 SDK
    [self.modules enumerateKeysAndObjectsUsingBlock:^(NSString *key, id<SAModuleProtocol> obj, BOOL *stop) {
        if (![obj conformsToProtocol:@protocol(SAPropertyModuleProtocol)] || !obj.isEnable) {
            return;
        }
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
        id<SAPropertyModuleProtocol> manager = (id<SAPropertyModuleProtocol>)obj;
        if ([key isEqualToString:kSALocationModuleName]) {
            [properties addEntriesFromDictionary:manager.properties];
        }
#endif
    }];
    return properties;
}

@end


#pragma mark -

@implementation SAModuleManager (ChannelMatch)

- (void)trackAppInstall:(NSString *)event properties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback {
    id<SAChannelMatchModuleProtocol> manager = (id<SAChannelMatchModuleProtocol>)[SAModuleManager.sharedInstance managerForModuleType:SAModuleTypeChannelMatch];
    [manager trackAppInstall:event properties:properties disableCallback:disableCallback];
}

@end
