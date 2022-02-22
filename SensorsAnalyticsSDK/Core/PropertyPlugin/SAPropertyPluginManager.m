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

const NSUInteger kSAPropertyPluginPrioritySuper = 1431656640;

@interface SAPropertyPluginFilter : NSObject

/// 用于保存筛选的事件名
@property (nonatomic, copy) NSString *event;
/// 用于保存筛选类型
@property (nonatomic, copy) NSString *type;
/// 用于保存筛选的属性名
@property (nonatomic, copy) NSDictionary<NSString *, id> *properties;

/// 用于筛选类名为 classes 数组中的属性插件（不包含自定义属性插件）
@property (nonatomic, strong) NSArray<Class> *classes;

- (instancetype)initWithClasses:(NSArray<Class> *)classes;

@end

@implementation SAPropertyPluginFilter

- (instancetype)initWithClasses:(NSArray<Class> *)classes {
    self = [super init];
    if (self) {
        _classes = classes;
    }
    return self;
}

@end

#pragma mark -

@interface SAPropertyPluginManager ()

@property (nonatomic, strong) NSMutableArray<id<SAPropertyPluginProtocol>> *plugins;
@property (nonatomic, strong) NSMutableArray<id<SAPropertyPluginProtocol>> *superPlugins;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<id<SAPropertyPluginProtocol>> *> *customPlugins;

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

- (void)registerPropertyPlugin:(id<SAPropertyPluginProtocol>)plugin {
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
        for (id<SAPropertyPluginProtocol> object in self.superPlugins) {
            if (object.class == plugin.class) {
                [self.superPlugins removeObject:object];
                break;
            }
        }
        [self.superPlugins addObject:plugin];
    } else {
        for (id<SAPropertyPluginProtocol> object in self.plugins) {
            if (object.class == plugin.class) {
                [self.plugins removeObject:object];
                break;
            }
        }
        [self.plugins addObject:plugin];
    }

    // 开始属性采集
    if ([plugin respondsToSelector:@selector(start)]) {
        [plugin start];
    }
}

- (void)registerCustomPropertyPlugin:(id<SAPropertyPluginProtocol>)plugin {
    NSString *key = NSStringFromClass(plugin.class);

    NSAssert([plugin respondsToSelector:@selector(properties)], @"You must implement `- properties` method!");
    if (!self.customPlugins[key]) {
        self.customPlugins[key] = [NSMutableArray array];
    }
    [self.customPlugins[key] addObject:plugin];

    // 开始属性采集
    if ([plugin respondsToSelector:@selector(start)]) {
        [plugin start];
    }
}

- (NSMutableDictionary<NSString *, id> *)currentPropertiesForPluginClasses:(NSArray<Class> *)classes {
    SAPropertyPluginFilter *filter = [[SAPropertyPluginFilter alloc] initWithClasses:classes];
    // 获取匹配的属性插件
    NSArray *plugins = [self pluginsWithFilter:filter];
    // 获取属性插件采集的属性
    NSMutableDictionary *pluginProperties = [self propertiesWithPlugins:plugins];

    // 获取匹配的属性插件
    NSArray *superPlugins = [self superPluginsWithFilter:filter];
    [pluginProperties addEntriesFromDictionary:[self propertiesWithPlugins:superPlugins]];

    return pluginProperties;
}

- (NSMutableDictionary<NSString *, id> *)propertiesWithEvent:(NSString *)name type:(NSString *)type properties:(NSDictionary<NSString *,id> *)properties {
    // 创建 Filter 对象
    SAPropertyPluginFilter *filter = [[SAPropertyPluginFilter alloc] init];
    filter.event = name;
    filter.type = type;
    return [self propertiesWithFilter:filter properties:properties];
}

#pragma mark - Properties

- (NSMutableDictionary<NSString *, id> *)propertiesWithFilter:(SAPropertyPluginFilter *)filter properties:(NSDictionary<NSString *,id> *)properties {
    // 获取匹配的自定义属性插件
    NSArray *customPlugins = [self customPluginsWithFilter:filter];

    filter.properties = properties;

    // 获取匹配的属性插件
    NSMutableArray *plugins = [self pluginsWithFilter:filter];
    [plugins addObjectsFromArray:customPlugins];

    // 获取匹配的属性插件
    [plugins addObjectsFromArray:[self superPluginsWithFilter:filter]];

    // 获取属性插件采集的属性
    return [self propertiesWithPlugins:plugins];
}

- (NSMutableDictionary *)propertiesWithPlugins:(NSArray<id<SAPropertyPluginProtocol>> *)plugins {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 按优先级排序
    [plugins sortedArrayUsingComparator:^NSComparisonResult(id<SAPropertyPluginProtocol> obj1, id<SAPropertyPluginProtocol> obj2) {
        SAPropertyPluginPriority priority1 = [obj1 respondsToSelector:@selector(priority)] ? obj1.priority : SAPropertyPluginPriorityDefault;
        SAPropertyPluginPriority priority2 = [obj2 respondsToSelector:@selector(priority)] ? obj2.priority : SAPropertyPluginPriorityDefault;
        return priority1 < priority2;
    }];
    // 获取匹配的插件属性
    dispatch_semaphore_t semaphore;
    for (id<SAPropertyPluginProtocol> plugin in plugins) {
        if ([plugin respondsToSelector:@selector(setPropertyPluginCompletion:)]) {
            // 如果插件异步获取属性，创建信号量
            semaphore = dispatch_semaphore_create(0);
            [plugin setPropertyPluginCompletion:^(NSDictionary<NSString *,id> * _Nonnull p) {
                [properties addEntriesFromDictionary:p];
                // 插件采集完成，释放信号量
                dispatch_semaphore_signal(semaphore);
            }];
        }
        NSDictionary *pluginProperties = [plugin respondsToSelector:@selector(properties)] ? plugin.properties : nil;
        if (pluginProperties) {
            [properties addEntriesFromDictionary:pluginProperties];
        } else if (semaphore) {
            // 等待插件采集完成
            dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)));
        }
        // 将信号量置空
        semaphore = nil;
    }
    return properties;
}

#pragma mark - Plugins

- (NSMutableArray<id<SAPropertyPluginProtocol>> *)customPluginsWithFilter:(SAPropertyPluginFilter *)filter {
    NSDictionary *dic = [self.customPlugins copy];
    NSMutableArray<id<SAPropertyPluginProtocol>> *matchPlugins = [NSMutableArray array];
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableArray<id<SAPropertyPluginProtocol>> *obj, BOOL *stop) {
        if ([self isMatchedWithPlugin:obj.firstObject filter:filter]) {
            [matchPlugins addObject:obj.firstObject];
            [self.customPlugins[key] removeObjectAtIndex:0];
        }
    }];
    return matchPlugins;
}

- (NSMutableArray<id<SAPropertyPluginProtocol>> *)pluginsWithFilter:(SAPropertyPluginFilter *)filter {
    NSArray *array = [self.plugins copy];
    NSMutableArray<id<SAPropertyPluginProtocol>> *matchPlugins = [NSMutableArray array];
    for (id<SAPropertyPluginProtocol> obj in array) {
        if ([self isMatchedWithPlugin:obj filter:filter]) {
            [matchPlugins addObject:obj];
        }
    }
    return matchPlugins;
}

- (NSMutableArray<id<SAPropertyPluginProtocol>> *)superPluginsWithFilter:(SAPropertyPluginFilter *)filter {
    NSArray *array = [self.superPlugins copy];
    NSMutableArray<id<SAPropertyPluginProtocol>> *matchPlugins = [NSMutableArray array];
    for (id<SAPropertyPluginProtocol> obj in array) {
        if ([self isMatchedWithPlugin:obj filter:filter]) {
            [matchPlugins addObject:obj];
        }
    }
    return matchPlugins;
}

#pragma mark - Matched

- (BOOL)isMatchedWithPlugin:(id<SAPropertyPluginProtocol>)plugin filter:(SAPropertyPluginFilter *)filter {
    if (!plugin) {
        return NO;
    }
    for (Class cla in filter.classes) {
        if ([plugin isKindOfClass:cla]) {
            return YES;
        }
    }
    // 事件名是否匹配
    // 事件类型是否匹配
    // 事件自定义属性是否匹配
    return [self isMatchedWithPlugin:plugin eventName:filter.event] && [self isMatchedWithPlugin:plugin eventType:filter.type] && [self isMatchedWithPlugin:plugin properties:filter.properties];
}

- (BOOL)isMatchedWithPlugin:(id<SAPropertyPluginProtocol>)plugin properties:(NSDictionary<NSString *,id> *)properties {
    if (![plugin respondsToSelector:@selector(propertyKeyFilter)]) {
        return YES;
    }
    NSArray *propertyKeyFilter = plugin.propertyKeyFilter;
    if (![propertyKeyFilter isKindOfClass:[NSArray class]]) {
        return YES;
    }
    for (NSString *key in propertyKeyFilter) {
        if (!properties[key]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isMatchedWithPlugin:(id<SAPropertyPluginProtocol>)plugin eventName:(NSString *)name {
    if (![plugin respondsToSelector:@selector(eventNameFilter)]) {
        return YES;
    }
    NSArray *eventNameFilter = plugin.eventNameFilter;
    if (![eventNameFilter isKindOfClass:[NSArray class]]) {
        return YES;
    }
    return [eventNameFilter containsObject:name];
}

- (BOOL)isMatchedWithPlugin:(id<SAPropertyPluginProtocol>)plugin eventType:(NSString *)type {
    if (![plugin respondsToSelector:@selector(eventTypeFilter)]) {
        // 默认为 track
        return [type isEqualToString:kSAEventTypeTrack];
    }
    SAPropertyPluginEventTypes eventTypeFilter = plugin.eventTypeFilter;
    if (eventTypeFilter == SAPropertyPluginEventTypeAll) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeTrack &&
        [type isEqualToString:kSAEventTypeTrack]) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeSignup &&
        [type isEqualToString:kSAEventTypeSignup]) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeProfileSet &&
        [type isEqualToString:SA_PROFILE_SET]) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeProfileSetOnce &&
        [type isEqualToString:SA_PROFILE_SET_ONCE]) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeProfileUnset &&
        [type isEqualToString:SA_PROFILE_UNSET]) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeProfileDelete &&
        [type isEqualToString:SA_PROFILE_DELETE]) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeProfileAppend &&
        [type isEqualToString:SA_PROFILE_APPEND]) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeIncrement &&
        [type isEqualToString:SA_PROFILE_INCREMENT]) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeItemSet &&
        [type isEqualToString:SA_EVENT_ITEM_SET]) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeItemDelete &&
        [type isEqualToString:SA_EVENT_ITEM_DELETE]) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeBind &&
        [type isEqualToString:kSAEventTypeBind]) {
        return YES;
    }
    if (eventTypeFilter & SAPropertyPluginEventTypeUnbind &&
        [type isEqualToString:kSAEventTypeUnbind]) {
        return YES;
    }

    return NO;
}

+ (SAPropertyPluginEventTypes)propertyPluginEventTypeWithEventType:(NSString *)type {
    if ([type isEqualToString:kSAEventTypeTrack]) {
        return SAPropertyPluginEventTypeTrack;
    }
    if ([type isEqualToString:kSAEventTypeSignup]) {
        return SAPropertyPluginEventTypeSignup;
    }
    if ([type isEqualToString:SA_PROFILE_SET]) {
        return SAPropertyPluginEventTypeProfileSet;
    }
    if ([type isEqualToString:SA_PROFILE_SET_ONCE]) {
        return SAPropertyPluginEventTypeProfileSetOnce;
    }
    if ([type isEqualToString:SA_PROFILE_UNSET]) {
        return SAPropertyPluginEventTypeProfileUnset;
    }
    if ([type isEqualToString:SA_PROFILE_DELETE]) {
        return SAPropertyPluginEventTypeProfileDelete;
    }
    if ([type isEqualToString:SA_PROFILE_APPEND]) {
        return SAPropertyPluginEventTypeProfileAppend;
    }
    if ([type isEqualToString:SA_PROFILE_INCREMENT]) {
        return SAPropertyPluginEventTypeIncrement;
    }
    if ([type isEqualToString:SA_EVENT_ITEM_SET]) {
        return SAPropertyPluginEventTypeItemSet;
    }
    if ([type isEqualToString:SA_EVENT_ITEM_DELETE]) {
        return SAPropertyPluginEventTypeItemDelete;
    }
    return SAPropertyPluginEventTypeAll;
}

@end

