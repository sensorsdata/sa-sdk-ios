//
//  SASDKRemoteConfig.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/4/24.
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
static NSInteger kSAAutoTrackModeDefault = -1;//-1，表示不修改现有的 autoTrack 方式 。0 代表禁用所有的 autoTrack 。其他 1～15 为合法数据
static NSInteger kSAAutoTrackModeDisabledAll = 0;
static NSInteger kSAAutoTrackModeEnabledAll = 15;

@interface SASDKRemoteConfig : NSObject
@property (nonatomic, copy) NSString *v;
@property (nonatomic, assign) BOOL disableSDK;
@property (nonatomic, assign) BOOL disableDebugMode;
@property (nonatomic, assign) NSInteger autoTrackMode;//-1,0,1~15

//本地保存 SDK 版本号
@property(nonatomic,copy)NSString *localLibVersion;

+ (instancetype)configWithDict:(NSDictionary *)dict;
- (instancetype)initWithDict:(NSDictionary *)dict;
@end
