//
//  SASDKRemoteConfig.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/4/24.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import "SASDKRemoteConfig.h"

BOOL isAutoTrackModeValid(NSInteger autoTrackMode){
    BOOL valid = NO;
    if (autoTrackMode >= kSAAutoTrackModeDefault && autoTrackMode <= kSAAutoTrackModeEnabledAll) {
        valid = YES;
    }
    return valid;
}

@interface SASDKRemoteConfig()

@end
@implementation SASDKRemoteConfig
+ (instancetype)configWithDict:(NSDictionary *)dict{
    return [[self alloc]initWithDict:dict];
}
-(instancetype)initWithDict:(NSDictionary *)dict{
    if (self = [super init]) {
        self.autoTrackMode = kSAAutoTrackModeDefault;
        self.v = [dict valueForKey:@"v"];
        self.disableSDK = [[dict valueForKeyPath:@"configs.disableSDK"] boolValue];
        self.disableDebugMode = [[dict valueForKeyPath:@"configs.disableDebugMode"] boolValue];
        NSNumber *autoTrackMode = [dict valueForKeyPath:@"configs.autoTrackMode"];
        if (autoTrackMode != nil) {
            NSInteger iMode = autoTrackMode.integerValue;
            if (isAutoTrackModeValid(iMode)) {
                self.autoTrackMode = iMode;
            }
        }
    }
    return self;
}

-(NSString *)description {
    return [[NSString alloc]initWithFormat:@"<%@:%p>,v=%@,disableSDK=%d,disableDebugMode=%d,autoTrackMode=%ld",self.class,self,self.v,self.disableSDK,self.disableDebugMode,(long)self.autoTrackMode];
}

@end
