//
//  SASDKRemoteConfig.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/4/24.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>
static NSInteger kSAAutoTrackModeDefault = -1;//-1，表示不修改现有的 autoTrack 方式 。0 代表禁用所有的 autoTrack 。其他 1～15 为合法数据
static NSInteger kSAAutoTrackModeDisabledAll = 0;
static NSInteger kSAAutoTrackModeEnabledAll = 15;

BOOL isAutoTrackModeValid(NSInteger autoTrackMode);

@interface SASDKRemoteConfig : NSObject
@property(nonatomic,copy)NSString *v;
@property(nonatomic,assign)BOOL disableSDK;
@property(nonatomic,assign)BOOL disableDebugMode;
@property(nonatomic,assign)NSInteger autoTrackMode;//-1,0,1~15

+ (instancetype)configWithDict:(NSDictionary *)dict;
- (instancetype)initWithDict:(NSDictionary *)dict;
@end
