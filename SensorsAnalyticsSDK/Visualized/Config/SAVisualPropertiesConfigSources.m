//
// SAVisualPropertiesConfigSources.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/7.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAVisualPropertiesConfigSources.h"
#import "UIViewController+AutoTrack.h"
#import "SAConstants+Private.h"
#import "SAAutoTrackUtils.h"
#import "SAReadWriteLock.h"
#import "SAReachability.h"
#import "SAFileStore.h"
#import "SAURLUtils.h"
#import "SAVisualizedLogger.h"
#import "SAJSONUtil.h"
#import "SALog.h"

static NSString * kSAConfigFileName = @"SAVisualPropertiesConfig";
static NSString * kSARequestConfigPath = @"config/visualized/iOS.conf";

static NSInteger const kSARequestConfigMaxTimes = 3;
typedef void(^SAVisualPropertiesConfigCompletionHandler)(BOOL success, SAVisualPropertiesResponse *_Nullable responseData);

/// 重试请求时间间隔，单位 秒
static NSTimeInterval const kRequestconfigRetryIntervalTime = 30;

@interface SAVisualPropertiesConfigSources()

/// 完整配置数据
@property (atomic, strong) SAVisualPropertiesResponse *configResponse;

@property(weak, nonatomic, nullable) id<SAConfigChangesDelegate> delegate;
@end

@implementation SAVisualPropertiesConfigSources

#pragma mark - initialize
- (instancetype)initWithDelegate:(id<SAConfigChangesDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - loadConfig
- (void)loadConfig {
    // 解析本地缓存
    [self unarchiveConfig];

    // 更新配置状态
    [self updateConfigStatus];

    //请求配置数据，失败则重试
    [self requestConfigWithTimes:kSARequestConfigMaxTimes];
}

- (void)setupConfigWithDictionary:(NSDictionary *)configDic disableConfig:(BOOL)disable {
    if (disable) { // 关闭自定义属性
        [self archiveConfig:nil];
    } else {
        SAVisualPropertiesResponse *config = [[SAVisualPropertiesResponse alloc] initWithDictionary:configDic];
        // 缓存数据
        [self archiveConfig:config];
    }
    
    // 更新配置状态
    [self updateConfigStatus];
}

/// 更新配置结果状态
- (void)updateConfigStatus {
    if ([self.delegate respondsToSelector:@selector(configChangedWithValid:)]) {
        [self.delegate configChangedWithValid:(self.isValid)];
    }
}

- (BOOL)isValid {
    return self.configResponse.events.count > 0;
}

- (NSString *)configVersion {
    return self.configResponse.version;
}

- (NSDictionary *)originalResponse {
    return self.configResponse.originalResponse;
}

#pragma mark - request
- (void)requestConfigWithTimes:(NSInteger)times {
    NSInteger requestIndex = times - 1;

    [self requestConfigWithCompletionHandler:^(BOOL success, SAVisualPropertiesResponse *_Nullable responseData) {
        if (requestIndex <= 0 || success) {
            return;
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRequestconfigRetryIntervalTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self requestConfigWithTimes:requestIndex];
        });
    }];
}

- (void)reloadConfig {
    // 更新最新缓存，并清除本地配置
    [self cleanConfig];

    NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"重设 serverURL，并清除配置缓存"];
    SALogDebug(@"%@", logMessage);
    [self requestConfigWithTimes:1];
}

- (void)requestConfigWithCompletionHandler:(SAVisualPropertiesConfigCompletionHandler)completionHandler {
    
    if (![SAReachability sharedInstance].reachable) {
        SALogWarn(@"The current network is unavailable, please check the network !");
        completionHandler(NO, nil);
        return;
    }
    
    // 拼接请求参数
    NSURLRequest *request = [self buildConfigRequest];
    if (!request) {
        return;
    }
    // 请求最新配置
    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        NSInteger statusCode = response.statusCode;
        /* statusCode 说明
         200：正常请求并正确返回配置
         304：如果本地配置和后端最新版本相同，则返回 304，同时配置为空
         205：配置不存在（未创建可视化全埋点事件或运维关闭自定义属性），此时配置为空，返回 205
         404：当前环境未包含此接口，可能 SA 版本比较低，暂不支持自定义属性
         */
        BOOL success = statusCode == 200 || statusCode == 304 || statusCode == 205 || statusCode == 404;
        SAVisualPropertiesResponse *config = nil;
        
        if (statusCode == 200) {
            @try {
                NSDictionary *dic = [SAJSONUtil JSONObjectWithData:data];
                if (dic) {
                    NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"获取可视化全埋点配置成功 %@", dic];
                    SALogInfo(@"【request visualProperties config】%@", logMessage);
                }
                
                SAVisualPropertiesResponse *config = [[SAVisualPropertiesResponse alloc] initWithDictionary:dic];
                
                // 缓存数据
                [self archiveConfig:config];
                
                // 更新配置状态
                [self updateConfigStatus];
            } @catch (NSException *exception) {
                NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"获取可视化全埋点配置，JSON 解析失败 %@", exception];
                SALogError(@"【request visualProperties config】%@", logMessage);
            }
        } else if (statusCode == 205) { // 配置不存在（未创建可视化全埋点事件或运维关闭自定义属性）
            // 清空配置
            [self cleanConfig];
            // 更新配置状态
            [self updateConfigStatus];

            NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"配置不存在（当前项目未创建可视化全埋点事件或运维关闭自定义属性），statusCode = %ld", (long)statusCode];
            SALogDebug(@"【request visualProperties config】%@", logMessage);
        } else if (statusCode > 200 && statusCode < 300) {
            NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"请求配置异常，statusCode = %ld",(long)statusCode];
            SALogWarn(@"【request visualProperties config】%@", logMessage);
        } else if (statusCode == 304) { // 未更新
            NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"可视化全埋点配置未更新，statusCode = %ld", (long)statusCode];
            SALogDebug(@"【request visualProperties config】%@", logMessage);
        } else if (statusCode == 404) {
            NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:[NSString stringWithFormat:@"请求配置失败，当前环境可能暂不支持自定义属性，statusCode = %ld", (long)statusCode]];
            SALogDebug(@"【request visualProperties config】%@", logMessage);
        } else {
            NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"请求配置出错，error: %@",error];
            SALogError(@"【request visualProperties config】%@", logMessage);
        }
        completionHandler(success, config);
    }];
    [task resume];
}

/// buildRequest
- (NSURLRequest *)buildConfigRequest {

    NSURLComponents *components = SensorsAnalyticsSDK.sharedInstance.network.baseURLComponents;
    if (!components) {
        NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"数据接收地址无效，serverURL: %@", SensorsAnalyticsSDK.sharedInstance.network.serverURL];
        SALogError(@"%@", logMessage);
        return nil;
    }

    components.query = nil;
    components.path = [components.path stringByAppendingPathComponent:kSARequestConfigPath];

    // 拼接参数
    NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionary];
    params[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    params[@"project"] = SensorsAnalyticsSDK.sharedInstance.network.project;

    // 当前配置版本
    if (self.configResponse) {
        params[@"v"] = self.configResponse.version;
    }

    // 拼接 queryItems
    NSString *queryItems =  [SAURLUtils urlQueryStringWithParams:params];
    components.query = queryItems;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"GET"];

    return request;
}

#pragma mark - archive
/// 解析本地本地缓存
- (void)unarchiveConfig {
    NSString *project = SensorsAnalyticsSDK.sharedInstance.network.project;

    NSData *data = [SAFileStore unarchiveWithFileName:kSAConfigFileName];
    SAVisualPropertiesResponse *config = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    if (!config) {
        NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"本地可视化全埋点无配置缓存"];
        SALogDebug(@"%@", logMessage);
        return;
    }

    // 合法性校验
    if ([config.project isEqualToString:project] && [config.os isEqualToString:@"iOS"]) {
        self.configResponse = config;

        NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"获取本地配置成功：%@", config.originalResponse];
        SALogInfo(@"%@", logMessage);
    } else {
        NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取配置" message:@"本地缓存可视化全埋点配置校验失败，App 当前 project 为 %@，缓存配置 project 为 %@，配置 os 为 %@", project, config.project, config.os];
        SALogWarn(@"%@", logMessage);
    }
}

/// 写入本地缓存
- (void)archiveConfig:(SAVisualPropertiesResponse *)config {
    // 存储到本地
    self.configResponse = config;

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:config];
    [SAFileStore archiveWithFileName:kSAConfigFileName value:data];
}

/// 清除配置缓存
- (void)cleanConfig {
    self.configResponse = nil;
    // 清除文件缓存
    [SAFileStore archiveWithFileName:kSAConfigFileName value:nil];
}

#pragma mark - queryConfig
/// 查询 view 配置
- (nullable NSArray <SAVisualPropertiesConfig *> *)propertiesConfigsWithViewNode:(SAViewNode *)viewNode {
    NSArray<SAVisualPropertiesConfig *> *configSources = self.configResponse.events;
    if (configSources.count == 0 || !viewNode) {
        return nil;
    }

    NSMutableArray *configs = [NSMutableArray array];
    // 查询元素点击事件配置
    for (SAVisualPropertiesConfig *config in configSources) {
        // 普通可视化全埋点事件，不包含自定义属性，直接跳过
        if (config.properties.count == 0 || !config.event) {
            continue;
        }
        // 命中配置信息
        if (config.eventType == SensorsAnalyticsEventTypeAppClick && [config.event isMatchVisualEventWithViewIdentify:viewNode]) {
            [configs addObject:config];
        }
    }
    return configs.count > 0 ? configs : nil;
}

/// 根据事件信息查询配置
- (nullable NSArray <SAVisualPropertiesConfig *> *)propertiesConfigsWithEventIdentifier:(SAEventIdentifier *)eventIdentifier {

    NSArray<SAVisualPropertiesConfig *> *configSources = self.configResponse.events;
    if (configSources.count == 0 || !eventIdentifier || eventIdentifier.eventType != SensorsAnalyticsEventTypeAppClick) {
        return nil;
    }

    NSMutableArray <SAVisualPropertiesConfig *>*configs = [NSMutableArray array];
    for (SAVisualPropertiesConfig *config in configSources) {
        // 命中 AppClick 配置
        if (config.eventType == SensorsAnalyticsEventTypeAppClick && [config.event isMatchVisualEventWithViewIdentify:eventIdentifier]) {
            [configs addObject:config];
        }
    }
    return configs.count > 0 ? [configs copy] : nil;
}

@end
