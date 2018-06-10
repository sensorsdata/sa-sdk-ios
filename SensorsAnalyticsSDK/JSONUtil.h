//
//  JSONUtil.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/7.
//  Copyright (c) 2015年 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSONUtil : NSObject

/**
 *  @abstract
 *  把一个Object转成Json字符串
 *
 *  @param obj 要转化的对象Object
 *
 *  @return 转化后得到的字符串
 */
- (NSData *)JSONSerializeObject:(id)obj;

/**
 *  初始化
 *
 *  @return 初始化后的对象
 */
- (id) init;

@end
