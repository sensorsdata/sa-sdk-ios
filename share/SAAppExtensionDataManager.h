//
//  SAAppExtensionDataManager.h
//  SensorsAnalyticsSDK
//
//  Created by ziven.mac on 2018/1/18.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 SAAppExtensionDataManager 扩展应用的数据管理类
 */
@interface SAAppExtensionDataManager : NSObject {
    
    NSArray* _groupIdentifierArray;
    
}

/**
 * @property
 *
 * @abstract
 * ApplicationGroupIdentifier数组
 */
@property(nonatomic,strong)NSArray *groupIdentifierArray;

+(instancetype)sharedInstance;

/**
 @abstract 根据传入的ApplicationGroupIdentifier 返回对应Extension的数据缓存路径
 
 @param groupIdentifier ApplicationGroupIdentifier
 @return 在group中的数据缓存路径
 */
-(NSString *)filePathForApplicationGroupIdentifier:(NSString *)groupIdentifier;

/**
 @abstract 根据传入的ApplicationGroupIdentifier 返回对应Extension当前缓存的事件数量
 @param groupIdentifier ApplicationGroupIdentifier
 @return 在该group中当前缓存的事件数量
 */
-(NSUInteger)fileDataCountForGroupIdentifier:(NSString *)groupIdentifier;

/**
 @abstract 从指定路径限量读取缓存的数据
 @param path 缓存路径
 @param limit 限定读取数，不足则返回当前缓存的全部数据
 @return 路径限量读取limit条数据，当前的缓存的事件数量不足limit，则返回当前缓存的全部数据
 */
-(NSArray *)fileDataArrayWithPath:(NSString *)path limit:(NSUInteger)limit;

/**
 @abstract 给一个groupIdentifier写入事件和属性
 @param eventName 事件名称(！须符合变量的命名规范)
 @param properties 事件属性
 @param groupIdentifier ApplicationGroupIdentifier
 @return 是否（YES/NO）写入成功
 */
-(BOOL)writeEvent:(NSString *)eventName properties:(NSDictionary *)properties groupIdentifier:(NSString *)groupIdentifier;

/**
 @abstract 读取groupIdentifier的所有缓存事件
 @param groupIdentifier ApplicationGroupIdentifier
 @return 当前groupIdentifier缓存的所有事件
 */
-(NSArray *)readAllEventsWithGroupIdentifier:(NSString *)groupIdentifier;

/**
 @abstract 删除groupIdentifier的所有缓存事件
 @param groupIdentifier ApplicationGroupIdentifier
 @return 是否（YES/NO）删除成功
 */
-(BOOL)deleteEventsWithGroupIdentifier:(NSString *)groupIdentifier;

@end
