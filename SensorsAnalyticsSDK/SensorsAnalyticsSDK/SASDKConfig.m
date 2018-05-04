//
//  SASDKConfig.m
//  SensorsAnalyticsSDK
//
//  Created by ziven.mac on 2018/4/24.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import "SASDKConfig.h"

@implementation SASDKConfig
+ (instancetype)configWithDict:(NSDictionary *)dict{
    return [[self alloc]initWithDict:dict];
}
-(instancetype)initWithDict:(NSDictionary *)dict{
    if (self = [super init]) {
        self.v = [dict valueForKey:@"v"];
        self.disableSDK = [[dict valueForKeyPath:@"configs.disableSDK"] boolValue] ;
        self.disableDebugMode = [[dict valueForKeyPath:@"configs.disableDebugMode"] boolValue];
    }
    return self;
}
@end
