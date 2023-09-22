//
// SAConstants+Private.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2019/4/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import "SAConstants.h"

#pragma mark - Track Timer
extern NSString * const kSAEventIdSuffix;

#pragma mark--evnet
extern NSString * const kSAEventTime;
extern NSString * const kSAEventTrackId;
extern NSString * const kSAEventName;
extern NSString * const kSAEventDistinctId;
extern NSString * const kSAEventOriginalId;
extern NSString * const kSAEventProperties;
extern NSString * const kSAEventType;
extern NSString * const kSAEventLib;
extern NSString * const kSAEventProject;
extern NSString * const kSAEventToken;
extern NSString * const kSAEventHybridH5;
extern NSString * const kSAEventLoginId;
extern NSString * const kSAEventAnonymousId;
extern NSString * const kSAEventIdentities;

#pragma mark - Item
extern NSString * const kSAEventItemSet;
extern NSString * const kSAEventItemDelete;

#pragma mark--evnet nanme

// App 启动或激活
extern NSString * const kSAEventNameAppStart;
// App 退出或进入后台
extern NSString * const kSAEventNameAppEnd;
// App 浏览页面
extern NSString * const kSAEventNameAppViewScreen;
// App 元素点击
extern NSString * const kSAEventNameAppClick;
/// Web 元素点击
extern NSString * const kSAEventNameWebClick;
// 自动追踪相关事件及属性
extern NSString * const kSAEventNameAppStartPassively;

extern NSString * const kSAEventNameSignUp;

extern NSString * const kSAEventNameAppCrashed;

extern NSString * const kSAEventNameAppRemoteConfigChanged;

// 绑定事件
extern NSString * const kSAEventNameBind;
// 解绑事件
extern NSString * const kSAEventNameUnbind;

#pragma mark--app install property
extern NSString * const kSAEventPropertyInstallSource;
extern NSString * const kSAEventPropertyInstallDisableCallback;
extern NSString * const kSAEventPropertyAppInstallFirstVisitTime;

#pragma mark--autoTrack property
// App 浏览页面 Url
extern NSString * const kSAEventPropertyScreenUrl;
// App 浏览页面 Referrer Url
extern NSString * const kSAEventPropertyScreenReferrerUrl;
extern NSString * const kSAEventPropertyElementId;
extern NSString * const kSAEventPropertyScreenName;
extern NSString * const kSAEventPropertyTitle;
extern NSString * const kSAEventPropertyElementPosition;
extern NSString * const kSAEventPropertyElementPath;
extern NSString * const kSAEventPropertyElementContent;
extern NSString * const kSAEventPropertyElementType;
extern NSString * const kSAEeventPropertyReferrerTitle;

// 远程控制配置信息
extern NSString * const kSAEventPropertyAppRemoteConfig;

#pragma mark--common property
//可选参数
extern NSString * const kSAEventCommonOptionalPropertyProject;
extern NSString * const kSAEventCommonOptionalPropertyToken;
extern NSString * const kSAEventCommonOptionalPropertyTime;
extern int64_t const kSAEventCommonOptionalPropertyTimeInt;

#pragma mark--lib method
extern NSString * const kSALibMethodAuto;
extern NSString * const kSALibMethodCode;

#pragma mark--track
extern NSString * const kSAEventTypeTrack;
extern NSString * const kSAEventTypeSignup;
extern NSString * const kSAEventTypeBind;
extern NSString * const kSAEventTypeUnbind;

#pragma mark--profile
extern NSString * const kSAProfileSet;
extern NSString * const kSAProfileSetOnce;
extern NSString * const kSAProfileUnset;
extern NSString * const kSAProfileDelete;
extern NSString * const kSAProfileAppend;
extern NSString * const kSAProfileIncrement;

#pragma mark - bridge name
extern NSString * const SA_SCRIPT_MESSAGE_HANDLER_NAME;

#pragma mark - reserved property list
NSSet* sensorsdata_reserved_properties(void);

#pragma mark - safe sync
BOOL sensorsdata_is_same_queue(dispatch_queue_t queue);

void sensorsdata_dispatch_safe_sync(dispatch_queue_t queue,
                                    DISPATCH_NOESCAPE dispatch_block_t block);

#pragma mark - Localization
NSString* sensorsdata_localized_string(NSString* key, NSString* value);

#define SALocalizedString(key) \
        sensorsdata_localized_string((key), nil)
#define SALocalizedStringWithDefaultValue(key, value) \
        sensorsdata_localized_string((key), (value))

#pragma mark - SF related notifications
extern NSNotificationName const SA_TRACK_EVENT_NOTIFICATION;
extern NSNotificationName const SA_TRACK_LOGIN_NOTIFICATION;
extern NSNotificationName const SA_TRACK_LOGOUT_NOTIFICATION;
extern NSNotificationName const SA_TRACK_IDENTIFY_NOTIFICATION;
extern NSNotificationName const SA_TRACK_RESETANONYMOUSID_NOTIFICATION;
extern NSNotificationName const SA_TRACK_EVENT_H5_NOTIFICATION;

#pragma mark - ABTest related notifications
/// 注入打通 bridge
extern NSNotificationName const SA_H5_BRIDGE_NOTIFICATION;

/// H5 通过 postMessage 发送消息
extern NSNotificationName const SA_H5_MESSAGE_NOTIFICATION;

#pragma mark - SA notifications
extern NSNotificationName const SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION;

/// 接收 App 内嵌 H5 可视化相关页面元素信息
extern NSNotificationName const kSAVisualizedMessageFromH5Notification;

// page leave
extern NSString * const kSAEventDurationProperty;
extern NSString * const kSAEventNameAppPageLeave;


//event name、property key、value max length
extern NSInteger kSAEventNameMaxLength;
extern NSInteger kSAPropertyValueMaxLength;

#pragma mark - SA Visualized
/// H5 可视化全埋点事件标记
extern NSString * const kSAWebVisualEventName;
/// 内嵌 H5 可视化全埋点 App 自定义属性配置
extern NSString * const kSAAppVisualProperties;
/// 内嵌 H5 可视化全埋点 Web 自定义属性配置
extern NSString * const kSAWebVisualProperties;

/// is instant event
extern NSString * const kSAInstantEventKey;
extern NSString * const kAdsEventKey;

//flush related keys
extern NSString * const kSAEncryptRecordKeyEKey;
extern NSString * const kSAEncryptRecordKeyPayloads;
extern NSString * const kSAEncryptRecordKeyPayload;
extern NSString * const kSAEncryptRecordKeyFlushTime;
extern NSString * const kSAEncryptRecordKeyPKV;
extern NSString * const kSAFlushBodyKeyData;
extern NSString * const kSAFlushBodyKeyGzip;
extern NSInteger const kSAFlushGzipCodePlainText;
extern NSInteger const kSAFlushGzipCodeEncrypt;
extern NSInteger const kSAFlushGzipCodeTransportEncrypt;

//remote config
extern NSString * const kSDKConfigKey;
extern NSString * const kRequestRemoteConfigRandomTimeKey; // 保存请求远程配置的随机时间 @{@"randomTime":@double,@"startDeviceTime":@double}
extern NSString * const kRandomTimeKey;
extern NSString * const kStartDeviceTimeKey;
extern NSString * const kSARemoteConfigSupportTransportEncryptKey;
extern NSString * const kSARemoteConfigConfigsKey;
