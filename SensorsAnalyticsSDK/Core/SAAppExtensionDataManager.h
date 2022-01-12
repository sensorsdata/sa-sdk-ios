//
// SAAppExtensionDataManager.h
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/1/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

/**
 SAAppExtensionDataManager 扩展应用的数据管理类
 */
@interface SAAppExtensionDataManager : NSObject {
    NSArray * _groupIdentifierArray;
}

/**
 * @property
 *
 * @abstract
 * ApplicationGroupIdentifier数组
 */
@property (nonatomic, strong) NSArray *groupIdentifierArray;

+ (instancetype)sharedInstance;

/**
 * @abstract
 * 根据传入的 ApplicationGroupIdentifier 返回对应 Extension 的数据缓存路径
 *
 * @param groupIdentifier ApplicationGroupIdentifier
 * @return 在 group 中的数据缓存路径
 */
- (NSString *)filePathForApplicationGroupIdentifier:(NSString *)groupIdentifier;

/**
 * @abstract
 * 根据传入的 ApplicationGroupIdentifier 返回对应 Extension 当前缓存的事件数量
 * @param groupIdentifier ApplicationGroupIdentifier
 * @return 在该 group 中当前缓存的事件数量
 */
- (NSUInteger)fileDataCountForGroupIdentifier:(NSString *)groupIdentifier;

/**
 * @abstract
 * 从指定路径限量读取缓存的数据
 * @param path 缓存路径
 * @param limit 限定读取数，不足则返回当前缓存的全部数据
 * @return 路径限量读取limit条数据，当前的缓存的事件数量不足 limit，则返回当前缓存的全部数据
 */
- (NSArray *)fileDataArrayWithPath:(NSString *)path limit:(NSUInteger)limit;

/**
 * @abstract
 * 给一个groupIdentifier写入事件和属性
 * @param eventName 事件名称(！须符合变量的命名规范)
 * @param properties 事件属性
 * @param groupIdentifier ApplicationGroupIdentifier
 * @return 是否（YES/NO）写入成功
 */
- (BOOL)writeEvent:(NSString *)eventName properties:(NSDictionary *)properties groupIdentifier:(NSString *)groupIdentifier;

/**
 * @abstract
 * 读取groupIdentifier的所有缓存事件
 * @param groupIdentifier ApplicationGroupIdentifier
 * @return 当前groupIdentifier缓存的所有事件
 */
- (NSArray *)readAllEventsWithGroupIdentifier:(NSString *)groupIdentifier;

/**
 * @abstract
 * 删除groupIdentifier的所有缓存事件
 * @param groupIdentifier ApplicationGroupIdentifier
 * @return 是否（YES/NO）删除成功
 */
- (BOOL)deleteEventsWithGroupIdentifier:(NSString *)groupIdentifier;

@end
