//
// SASessionProperty.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/12/23.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SASessionProperty.h"
#import "SAStoreManager.h"

/// session 标记
static NSString * const kSAEventPropertySessionID = @"$event_session_id";
/// session 数据模型
static NSString * const kSASessionModelKey = @"SASessionModel";
/// session 中事件最大间隔 30 分钟（单位为毫秒）
static const NSUInteger kSASessionMaxInterval = 30 * 60 * 1000;
/// session 最大时长是 12 小时（单位为毫秒）
static const NSUInteger kSASessionMaxDuration = 12 * 60 * 60 * 1000;

#pragma mark - SASessionModel

@interface SASessionModel : NSObject <NSCoding>

/// session 标识
@property (nonatomic, copy) NSString *sessionID;
/// 首个事件的触发时间
@property (nonatomic, strong) NSNumber *firstEventTime;
/// 最后一个事件的触发时间
@property (nonatomic, strong) NSNumber *lastEventTime;

@end

@implementation SASessionModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionID = [NSUUID UUID].UUIDString;
        _firstEventTime = @(0);
        _lastEventTime = @(0);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.sessionID forKey:@"sessionID"];
    [coder encodeObject:self.firstEventTime forKey:@"firstEventTime"];
    [coder encodeObject:self.lastEventTime forKey:@"lastEventTime"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.sessionID = [coder decodeObjectForKey:@"sessionID"];
        self.firstEventTime = [coder decodeObjectForKey:@"firstEventTime"];
        self.lastEventTime = [coder decodeObjectForKey:@"lastEventTime"];
    }
    return self;
}

- (NSString *)description {
    return [[NSString alloc] initWithFormat:@"<%@:%p>, \n sessionID = %@, \n firstEventTime = %@, \n lastEventTime = %@", self.class, self, self.sessionID, self.firstEventTime, self.lastEventTime];
}

@end

#pragma mark - SASessionProperty

@interface SASessionProperty ()

@property (nonatomic, strong) SASessionModel *sessionModel;

@end

@implementation SASessionProperty

#pragma mark - Public

+ (void)removeSessionModel {
    [[SAStoreManager sharedInstance] removeObjectForKey:kSASessionModelKey];
}

- (NSDictionary *)sessionPropertiesWithEventTime:(NSNumber *)eventTime {
    NSNumber *maxIntervalEventTime = @(self.sessionModel.lastEventTime.unsignedLongLongValue + kSASessionMaxInterval);
    NSNumber *maxDurationEventTime = @(self.sessionModel.firstEventTime.unsignedLongLongValue + kSASessionMaxDuration);
    
    // 重新生成 session
    if (([eventTime compare:maxIntervalEventTime] == NSOrderedDescending) ||
        ([eventTime compare:maxDurationEventTime] == NSOrderedDescending)) {
        self.sessionModel.sessionID = [NSUUID UUID].UUIDString;
        self.sessionModel.firstEventTime = eventTime;
    }
    
    // 更新最近一次事件的触发时间
    self.sessionModel.lastEventTime = eventTime;
    
    // session 保存本地
    [[SAStoreManager sharedInstance] setObject:self.sessionModel forKey:kSASessionModelKey];
    
    return @{kSAEventPropertySessionID : self.sessionModel.sessionID};
}

#pragma mark - Getters and Setters

/// 懒加载是为了防止在初始化的时候同步读取文件
- (SASessionModel *)sessionModel {
    if (!_sessionModel) {
        _sessionModel = [[SAStoreManager sharedInstance] objectForKey:kSASessionModelKey] ?: [[SASessionModel alloc] init];
    }
    return _sessionModel;
}

@end
