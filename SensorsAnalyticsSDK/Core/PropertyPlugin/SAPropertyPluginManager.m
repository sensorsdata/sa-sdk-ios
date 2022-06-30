//
// SAPropertyPluginManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/9/6.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAPropertyPluginManager.h"
#import "SAConstants+Private.h"
#import "SAPropertyPlugin+SAPrivate.h"

const NSUInteger kSAPropertyPluginPrioritySuper = 1431656640;

#pragma mark -

@interface SAPropertyPluginManager ()

@property (nonatomic, strong) NSMutableArray<SAPropertyPlugin *> *plugins;
@property (nonatomic, strong) NSMutableArray<SAPropertyPlugin *> *superPlugins;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<SAPropertyPlugin *> *> *customPlugins;

@end

#pragma mark -

@implementation SAPropertyPluginManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAPropertyPluginManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAPropertyPluginManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _plugins = [NSMutableArray array];
        _superPlugins = [NSMutableArray array];
        _customPlugins = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public

- (void)registerPropertyPlugin:(SAPropertyPlugin *)plugin {
    // 断言提示必须实现 properties 方法
    BOOL isResponds = [plugin respondsToSelector:@selector(properties)];
    NSAssert(isResponds, @"You must implement `- properties` method!");
    if (!isResponds) {
        return;
    }

    SAPropertyPluginPriority priority = [plugin respondsToSelector:@selector(priority)] ? plugin.priority : SAPropertyPluginPriorityDefault;
    // 断言提示返回的优先级类型必须为 SAPropertyPluginPriority
    NSAssert(priority == SAPropertyPluginPriorityLow || priority == SAPropertyPluginPriorityDefault || priority == SAPropertyPluginPriorityHigh || priority == kSAPropertyPluginPrioritySuper, @"Invalid value: the `- priority` method must return `SAPropertyPluginPriority` type.");

    if (priority == kSAPropertyPluginPrioritySuper) {
        for (SAPropertyPlugin *object in self.superPlugins) {
            if (object.class == plugin.class) {
                [self.superPlugins removeObject:object];
                break;
            }
        }
        [self.superPlugins addObject:plugin];
    } else {
        for (SAPropertyPlugin *object in self.plugins) {
            if (object.class == plugin.class) {
                [self.plugins removeObject:object];
                break;
            }
        }
        [self.plugins addObject:plugin];
    }

    if ([plugin respondsToSelector:@selector(prepare)]) {
        [plugin prepare];
    }
}

- (void)unregisterPropertyPluginWithPluginClass:(Class)cla {
    if (!cla) {
        return;
    }
    [self.superPlugins enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SAPropertyPlugin * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:cla]) {
            [self.superPlugins removeObject:obj];
            *stop = YES;
        }
    }];
    
    [self.plugins enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SAPropertyPlugin * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:cla]) {
            [self.plugins removeObject:obj];
            *stop = YES;
        }
    }];
}

- (void)registerCustomPropertyPlugin:(SAPropertyPlugin *)plugin {
    NSString *key = NSStringFromClass(plugin.class);

    NSAssert([plugin respondsToSelector:@selector(properties)], @"You must implement `- properties` method!");
    if (!self.customPlugins[key]) {
        self.customPlugins[key] = [NSMutableArray array];
    }
    [self.customPlugins[key] addObject:plugin];

    if ([plugin respondsToSelector:@selector(prepare)]) {
        [plugin prepare];
    };
}

- (NSMutableDictionary<NSString *, id> *)currentPropertiesForPluginClasses:(NSArray<Class> *)classes {
    NSMutableArray *plugins = [NSMutableArray array];
    for (SAPropertyPlugin *plugin in self.plugins) {
        if ([classes containsObject:plugin.class]) {
            [plugins addObject:plugin];
        }
    }
    // 获取属性插件采集的属性
    NSMutableDictionary *pluginProperties = [self propertiesWithPlugins:plugins filter:nil];

    NSMutableArray *superPlugins = [NSMutableArray array];
    for (SAPropertyPlugin *plugin in self.superPlugins) {
        if ([classes containsObject:plugin.class]) {
            [superPlugins addObject:plugin];
        }
    }
    [pluginProperties addEntriesFromDictionary:[self propertiesWithPlugins:superPlugins filter:nil]];

    return pluginProperties;
}

- (SAPropertyPlugin *)pluginsWithPluginClass:(Class)cla {
    if (!cla) {
        return nil;
    }
    NSMutableArray <SAPropertyPlugin *>*allPlugins = [NSMutableArray array];
    // 获取自定义属性插件
    for (NSArray *customPlugins in self.customPlugins.allValues) {
        // 可能是空数组
        if (customPlugins.count > 0) {
            [allPlugins addObject:customPlugins.firstObject];
        }
    }
    [allPlugins addObjectsFromArray:self.plugins];
    [allPlugins addObjectsFromArray:self.superPlugins];

    for (SAPropertyPlugin *plugin in allPlugins) {
        if ([plugin isKindOfClass:cla]) {
            return plugin;
        }
    }
    return nil;
}

#pragma mark - Properties
- (NSMutableDictionary<NSString *,id> *)propertiesWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    NSMutableArray <SAPropertyPlugin *>*allPlugins = [NSMutableArray array];

    // 获取匹配的自定义属性插件
    NSArray *customPlugins = [self customPluginsWithFilter:filter];
    if (customPlugins.count > 0) {
        [allPlugins addObjectsFromArray:customPlugins];
    }

    // 获取普通属性采集插件
    NSArray *presetPlugins = [self pluginsWithFilter:filter];
    if (presetPlugins.count > 0) {
        [allPlugins addObjectsFromArray:presetPlugins];
    }

    // 添加特殊优先级的属性插件采集的属性
    NSArray *superPlugins = [self superPluginsWithFilter:filter];
    if (superPlugins.count > 0) {
        [allPlugins addObjectsFromArray:superPlugins];
    }
    
    NSMutableDictionary *properties = [self propertiesWithPlugins:allPlugins filter:filter];
    return properties;
}

- (NSMutableDictionary *)propertiesWithPlugins:(NSArray<SAPropertyPlugin *> *)plugins filter:(id<SAPropertyPluginEventFilter>)filter {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 按优先级升序排序
    NSArray<SAPropertyPlugin *> *sortedPlugins = [plugins sortedArrayUsingComparator:^NSComparisonResult(SAPropertyPlugin *obj1, SAPropertyPlugin *obj2) {
        SAPropertyPluginPriority priority1 = [obj1 respondsToSelector:@selector(priority)] ? obj1.priority : SAPropertyPluginPriorityDefault;
        SAPropertyPluginPriority priority2 = [obj2 respondsToSelector:@selector(priority)] ? obj2.priority : SAPropertyPluginPriorityDefault;
        
        if (priority1 <= priority2) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    
    // 创建信号量
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    SAPropertyPluginHandler handler = ^(NSDictionary<NSString *,id> * _Nonnull p) {
        [properties addEntriesFromDictionary:p];
        // 插件采集完成，释放信号量
        dispatch_semaphore_signal(semaphore);
    };
    for (SAPropertyPlugin *plugin in sortedPlugins) {
        // 设置属性处理完成回调
        plugin.handler = handler;
        plugin.filter = filter;
        
        // 获取匹配的插件属性
        NSDictionary *pluginProperties = plugin.properties;
        // 避免插件未实现 prepare 接口，并且 properties 返回 nil 导致的阻塞问题
        if ([plugin respondsToSelector:@selector(prepare)] && !pluginProperties) {
            // 等待插件采集完成
            dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)));
        } else if (pluginProperties) {
            [properties addEntriesFromDictionary:pluginProperties];
        }
        
        // 清空 filter，防止影响其他采集
        plugin.filter = nil;
    }
    return properties;
}

#pragma mark - Plugins

- (NSMutableArray<SAPropertyPlugin *> *)customPluginsWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    NSDictionary *dic = [self.customPlugins copy];
    NSMutableArray<SAPropertyPlugin *> *matchPlugins = [NSMutableArray array];
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableArray<SAPropertyPlugin *> *obj, BOOL *stop) {
        if ([obj.firstObject isMatchedWithFilter:filter]) {
            [matchPlugins addObject:obj.firstObject];
            // 自定义属性插件，单次生效后移除
            [self.customPlugins[key] removeObjectAtIndex:0];
        }
    }];
    return matchPlugins;
}

- (NSMutableArray<SAPropertyPlugin *> *)pluginsWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    NSArray *array = [self.plugins copy];
    NSMutableArray<SAPropertyPlugin *> *matchPlugins = [NSMutableArray array];
    for (SAPropertyPlugin *obj in array) {
        if ([obj isMatchedWithFilter:filter]) {
            [matchPlugins addObject:obj];
        }
    }
    return matchPlugins;
}

- (NSMutableArray<SAPropertyPlugin *> *)superPluginsWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    NSArray *array = [self.superPlugins copy];
    NSMutableArray<SAPropertyPlugin *> *matchPlugins = [NSMutableArray array];
    for (SAPropertyPlugin *obj in array) {
        if ([obj isMatchedWithFilter:filter]) {
            [matchPlugins addObject:obj];
        }
    }
    return matchPlugins;
}

@end

