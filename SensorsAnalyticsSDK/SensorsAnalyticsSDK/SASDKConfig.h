//
//  SASDKConfig.h
//  SensorsAnalyticsSDK
//
//  Created by ziven.mac on 2018/4/24.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SASDKConfig : NSObject
@property(nonatomic,copy)NSString *v;
@property(nonatomic,assign)BOOL disableSDK;
@property(nonatomic,assign)BOOL disableDebugMode;
+ (instancetype)configWithDict:(NSDictionary *)dict;
- (instancetype)initWithDict:(NSDictionary *)dict;
@end
