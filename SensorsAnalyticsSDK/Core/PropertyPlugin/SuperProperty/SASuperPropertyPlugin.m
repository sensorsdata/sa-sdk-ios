//
// SASuperPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/4/22.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SASuperPropertyPlugin.h"
#import "SAPropertyValidator.h"
#import "SAStoreManager.h"
#import "SAEventLibObject.h"

static NSString *const kSASavedSuperPropertiesFileName = @"super_properties";

@interface SASuperPropertyPlugin ()
/// 静态公共属性
@property (atomic, strong) NSDictionary *superProperties;
@end


@implementation SASuperPropertyPlugin

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

- (void)prepare {
    [self unarchiveSuperProperties];
}

- (NSDictionary<NSString *,id> *)properties {
    return [self.superProperties copy];
}

#pragma mark - superProperties
- (void)registerSuperProperties:(NSDictionary *)propertyDict {
    NSDictionary *validProperty = [SAPropertyValidator validProperties:[propertyDict copy]];
    [self unregisterSameLetterSuperProperties:validProperty];
    // 注意这里的顺序，发生冲突时是以 propertyDict 为准，所以它是后加入的
    NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.properties];
    [tmp addEntriesFromDictionary:validProperty];
    self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
    [self archiveSuperProperties];
}

- (void)unregisterSuperProperty:(NSString *)propertyKey {
    if (!propertyKey) {
        return;
    }
    NSMutableDictionary *superProperties = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
    [superProperties removeObjectForKey:propertyKey];
    self.superProperties = [NSDictionary dictionaryWithDictionary:superProperties];
    [self archiveSuperProperties];
}

- (void)clearSuperProperties {
    self.superProperties = @{};
    [self archiveSuperProperties];
}

/// 注销仅大小写不同的 SuperProperties
/// @param propertyDict 公共属性
- (void)unregisterSameLetterSuperProperties:(NSDictionary *)propertyDict {
    NSArray *allNewKeys = [propertyDict.allKeys copy];
    //如果包含仅大小写不同的 key ,unregisterSuperProperty
    NSArray *superPropertyAllKeys = [self.superProperties.allKeys copy];
    NSMutableArray *unregisterPropertyKeys = [NSMutableArray array];
    for (NSString *newKey in allNewKeys) {
        [superPropertyAllKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *usedKey = (NSString *)obj;
            if ([usedKey caseInsensitiveCompare:newKey] == NSOrderedSame) { // 存在不区分大小写相同 key
                [unregisterPropertyKeys addObject:usedKey];
            }
        }];
    }
    if (unregisterPropertyKeys.count > 0) {
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.properties];
        [tmp removeObjectsForKeys:unregisterPropertyKeys];
        self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
    }
}

#pragma mark - 缓存

- (void)unarchiveSuperProperties {
    NSDictionary *archivedSuperProperties = [[SAStoreManager sharedInstance] objectForKey:kSASavedSuperPropertiesFileName];
    self.superProperties = archivedSuperProperties ? [archivedSuperProperties copy] : [NSDictionary dictionary];
}

- (void)archiveSuperProperties {
    [[SAStoreManager sharedInstance] setObject:self.superProperties forKey:kSASavedSuperPropertiesFileName];
}

@end
