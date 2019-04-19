//
//  MessageQueueBySqlite.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/7.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

/**
 *  @abstract
 *  一个基于Sqlite封装的接口，用于向其中添加和获取数据
 */
@interface MessageQueueBySqlite : NSObject


/**
 *  @abstract
 *  根据传入的文件路径初始化
 *
 *  @param filePath 传入的数据文件路径
 *
 *  @return 初始化的结果
 */
- (id)initWithFilePath:(NSString *)filePath;

/**
 *  @abstract
 *  向队列中添加一个对象
 *
 *  @param obj 添加的对象
 */
- (void)addObejct:(id)obj withType:(NSString *)type;

/**
 *  @abstract
 *  从队列最前端，获取指定数目的记录，获取的记录以json字符串的形式存放在数组中
 *
 *  @param recordSize 要获取的记录的条目数
 *
 *  @return 获取的记录所在的数组
 */
- (NSArray *) getFirstRecords:(NSUInteger)recordSize withType:(NSString *)type ;


/**
 *  @abstract
 *  从队列最前端，删除指定数量的记录
 *
 *  @param recordSize 要删除的记录的数量
 *
 *  @return 删除是否成功
 */
- (BOOL) removeFirstRecords:(NSUInteger)recordSize withType:(NSString *)type ;

/**
 *  @abstract
 *  删除本地缓存的全部事件
 *
 *  一旦调用该接口，将会删除本地缓存的全部事件，请慎用！
 */
- (void) deleteAll;

/**
 *  @abstract
 *  获取当前记录的数量
 *
 *  @return 当前记录的数量
 */
- (NSInteger) count;

/**
 *  @abstract
 *  缩减表格文件空洞数据的空间
 *
 *  @return 是否成功
 */
- (BOOL) vacuum;


@end
