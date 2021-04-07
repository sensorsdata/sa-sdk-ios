//
//  SAModuleProtocol.h
//  Pods
//
//  Created by 张敏超🍎 on 2020/8/12.
//  
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SASecretKey;
@class SAConfigOptions;

@protocol SAModuleProtocol <NSObject>

- (instancetype)init;

@property (nonatomic, assign, getter=isEnable) BOOL enable;

@optional

@property (nonatomic, strong) SAConfigOptions *configOptions;

@end

#pragma mark -

@protocol SAPropertyModuleProtocol <SAModuleProtocol>

@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end

#pragma mark -

@protocol SAOpenURLProtocol <NSObject>

- (BOOL)canHandleURL:(NSURL *)url;
- (BOOL)handleURL:(NSURL *)url;

@end

#pragma mark -

@protocol SAChannelMatchModuleProtocol <NSObject>

/**
 * @abstract
 * 用于在 App 首次启动时追踪渠道来源，并设置追踪渠道事件的属性。SDK 会将渠道值填入事件属性 $utm_ 开头的一系列属性中。
 *
 * @param event  event 的名称
 * @param properties     event 的属性
 * @param disableCallback     是否关闭这次渠道匹配的回调请求
*/
- (void)trackAppInstall:(NSString *)event properties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback;

@end

#pragma mark -

@protocol SAEncryptModuleProtocol <NSObject>

@property (nonatomic, readonly) BOOL hasSecretKey;

/// 用于远程配置回调中处理并保存密钥
/// @param encryptConfig 返回的
- (void)handleEncryptWithConfig:(NSDictionary *)encryptConfig;

/// 加密数据
/// @param obj 需要加密的 JSON 数据
/// @return 返回加密后的数据
- (nullable NSDictionary *)encryptJSONObject:(id)obj;

@end

@protocol SAAppPushModuleProtocol <NSObject>

- (void)setLaunchOptions:(NSDictionary *)launchOptions;

@end

#pragma mark -

@protocol SAGestureModuleProtocol <NSObject>

/// 校验可视化全埋点元素能否选中
/// @param obj 控件元素
/// @return 返回校验结果
- (BOOL)isGestureVisualView:(id)obj;

@end

NS_ASSUME_NONNULL_END
