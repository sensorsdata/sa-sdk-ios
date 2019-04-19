//
//  SASDKRemoteConfig.m
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SASDKRemoteConfig.h"

static BOOL isAutoTrackModeValid(NSInteger autoTrackMode) {
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
    return [[self alloc] initWithDict:dict];
}

- (instancetype)initWithDict:(NSDictionary *)dict{
    if (self = [super init]) {
        _autoTrackMode = kSAAutoTrackModeDefault;
        _v = [dict valueForKey:@"v"];
        _disableSDK = [[dict valueForKeyPath:@"configs.disableSDK"] boolValue];
        _disableDebugMode = [[dict valueForKeyPath:@"configs.disableDebugMode"] boolValue];
        NSNumber *autoTrackMode = [dict valueForKeyPath:@"configs.autoTrackMode"];
        if (autoTrackMode != nil) {
            NSInteger iMode = autoTrackMode.integerValue;
            if (isAutoTrackModeValid(iMode)) {
                _autoTrackMode = iMode;
            }
        }
    }
    return self;
}

- (NSString *)description {
    return [[NSString alloc] initWithFormat:@"<%@:%p>,v=%@,disableSDK=%d,disableDebugMode=%d,autoTrackMode=%ld",self.class, self, self.v, self.disableSDK, self.disableDebugMode, (long)self.autoTrackMode];
}

@end
