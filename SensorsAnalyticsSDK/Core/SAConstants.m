//
// SAConstants.m
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/8/9.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAConstants.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SACoreResources.h"

#pragma mark - Track Timer
NSString *const kSAEventIdSuffix = @"_SATimer";

#pragma mark - event
NSString * const kSAEventTime = @"time";
NSString * const kSAEventTrackId = @"_track_id";
NSString * const kSAEventName = @"event";
NSString * const kSAEventDistinctId = @"distinct_id";
NSString * const kSAEventOriginalId = @"original_id";
NSString * const kSAEventProperties = @"properties";
NSString * const kSAEventType = @"type";
NSString * const kSAEventLib = @"lib";
NSString * const kSAEventProject = @"project";
NSString * const kSAEventToken = @"token";
NSString * const kSAEventHybridH5 = @"_hybrid_h5";
NSString * const kSAEventLoginId = @"login_id";
NSString * const kSAEventAnonymousId = @"anonymous_id";
NSString * const kSAEventIdentities = @"identities";

#pragma mark - Item
NSString * const kSAEventItemSet = @"item_set";
NSString * const kSAEventItemDelete = @"item_delete";

#pragma mark - event name
// App 启动或激活
NSString * const kSAEventNameAppStart = @"$AppStart";
// App 退出或进入后台
NSString * const kSAEventNameAppEnd = @"$AppEnd";
// App 浏览页面
NSString * const kSAEventNameAppViewScreen = @"$AppViewScreen";
// App 元素点击
NSString * const kSAEventNameAppClick = @"$AppClick";
// web 元素点击
NSString * const kSAEventNameWebClick = @"$WebClick";

// 自动追踪相关事件及属性
NSString * const kSAEventNameAppStartPassively = @"$AppStartPassively";

NSString * const kSAEventNameSignUp = @"$SignUp";

NSString * const kSAEventNameAppCrashed = @"AppCrashed";
// 远程控制配置变化
NSString * const kSAEventNameAppRemoteConfigChanged = @"$AppRemoteConfigChanged";

// 绑定事件
NSString * const kSAEventNameBind = @"$BindID";
// 解绑事件
NSString * const kSAEventNameUnbind = @"$UnbindID";

#pragma mark - app install property
NSString * const kSAEventPropertyInstallSource = @"$ios_install_source";
NSString * const kSAEventPropertyInstallDisableCallback = @"$ios_install_disable_callback";
NSString * const kSAEventPropertyAppInstallFirstVisitTime = @"$first_visit_time";
#pragma mark - autoTrack property
// App 浏览页面 Url
NSString * const kSAEventPropertyScreenUrl = @"$url";
// App 浏览页面 Referrer Url
NSString * const kSAEventPropertyScreenReferrerUrl = @"$referrer";
NSString * const kSAEventPropertyElementId = @"$element_id";
NSString * const kSAEventPropertyScreenName = @"$screen_name";
NSString * const kSAEventPropertyTitle = @"$title";
NSString * const kSAEventPropertyElementPosition = @"$element_position";

NSString * const kSAEeventPropertyReferrerTitle = @"$referrer_title";

// 模糊路径
NSString * const kSAEventPropertyElementPath = @"$element_path";
NSString * const kSAEventPropertyElementContent = @"$element_content";
NSString * const kSAEventPropertyElementType = @"$element_type";
// 远程控制配置信息
NSString * const kSAEventPropertyAppRemoteConfig = @"$app_remote_config";

#pragma mark - common property
NSString * const kSAEventCommonOptionalPropertyProject = @"$project";
NSString * const kSAEventCommonOptionalPropertyToken = @"$token";
NSString * const kSAEventCommonOptionalPropertyTime = @"$time";
//神策成立时间，2015-05-15 10:24:00.000，某些时间戳判断（毫秒）
int64_t const kSAEventCommonOptionalPropertyTimeInt = 1431656640000;

#pragma mark--lib method
NSString * const kSALibMethodAuto = @"autoTrack";
NSString * const kSALibMethodCode = @"code";

#pragma mark--track type
NSString * const kSAEventTypeTrack = @"track";
NSString * const kSAEventTypeSignup = @"track_signup";
NSString * const kSAEventTypeBind = @"track_id_bind";
NSString * const kSAEventTypeUnbind = @"track_id_unbind";

#pragma mark - profile
NSString * const kSAProfileSet = @"profile_set";
NSString * const kSAProfileSetOnce = @"profile_set_once";
NSString * const kSAProfileUnset = @"profile_unset";
NSString * const kSAProfileDelete = @"profile_delete";
NSString * const kSAProfileAppend = @"profile_append";
NSString * const kSAProfileIncrement = @"profile_increment";

#pragma mark - bridge name
NSString * const SA_SCRIPT_MESSAGE_HANDLER_NAME = @"sensorsdataNativeTracker";

NSSet* sensorsdata_reserved_properties(void) {
    return [NSSet setWithObjects:@"date", @"datetime", @"distinct_id", @"event", @"events", @"first_id", @"id", @"original_id", @"properties", @"second_id", @"time", @"user_id", @"users", nil];
}

BOOL sensorsdata_is_same_queue(dispatch_queue_t queue) {
    return strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0;
}

void sensorsdata_dispatch_safe_sync(dispatch_queue_t queue,DISPATCH_NOESCAPE dispatch_block_t block) {
    if ((dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)) == dispatch_queue_get_label(queue)) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}

#pragma mark - Localization
NSString* sensorsdata_localized_string(NSString* key, NSString* value) {
    static NSDictionary *languageResources = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

    // 加载语言资源
    languageResources = [SACoreResources defaultLanguageResources];

    });

    return languageResources[key] ?: value;
}

#pragma mark - SF related notifications
NSNotificationName const SA_TRACK_EVENT_NOTIFICATION = @"SensorsAnalyticsTrackEventNotification";
NSNotificationName const SA_TRACK_LOGIN_NOTIFICATION = @"SensorsAnalyticsTrackLoginNotification";
NSNotificationName const SA_TRACK_LOGOUT_NOTIFICATION = @"SensorsAnalyticsTrackLogoutNotification";
NSNotificationName const SA_TRACK_IDENTIFY_NOTIFICATION = @"SensorsAnalyticsTrackIdentifyNotification";
NSNotificationName const SA_TRACK_RESETANONYMOUSID_NOTIFICATION = @"SensorsAnalyticsTrackResetAnonymousIdNotification";
NSNotificationName const SA_TRACK_EVENT_H5_NOTIFICATION = @"SensorsAnalyticsTrackEventFromH5Notification";
NSNotificationName const SA_TRACK_Set_Server_URL_NOTIFICATION = @"SensorsAnalyticsSetServerUrlNotification";

#pragma mark - ABTest related notifications
NSNotificationName const SA_H5_BRIDGE_NOTIFICATION = @"SensorsAnalyticsRegisterJavaScriptBridgeNotification";

NSNotificationName const SA_H5_MESSAGE_NOTIFICATION = @"SensorsAnalyticsMessageFromH5Notification";

#pragma mark - other
// 远程配置更新
NSNotificationName const SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION = @"cn.sensorsdata.SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION";

// 接收 App 内嵌 H5 可视化相关页面元素信息
NSNotificationName const kSAVisualizedMessageFromH5Notification = @"SensorsAnalyticsVisualizedMessageFromH5Notification";

//page leave
NSString * const kSAEventDurationProperty = @"event_duration";
NSString * const kSAEventNameAppPageLeave = @"$AppPageLeave";

//event name、property key、value max length
NSInteger kSAEventNameMaxLength = 100;
NSInteger kSAPropertyValueMaxLength = 8192;

#pragma mark - SA Visualized
/// 埋点校验中，$WebClick 匹配可视化全埋点的事件名（集合）
NSString * const kSAWebVisualEventName = @"sensorsdata_web_visual_eventName";

/// App 内嵌 H5 的 Web 事件，属性配置中，需要 App 采集的属性
NSString * const kSAAppVisualProperties = @"sensorsdata_app_visual_properties";

/// App 内嵌 H5 的 Native 事件，属性配置中，需要 web 采集的属性
NSString * const kSAWebVisualProperties = @"sensorsdata_js_visual_properties";

SALimitKey const SALimitKeyIDFA = @"SALimitKeyIDFA";
SALimitKey const SALimitKeyIDFV = @"SALimitKeyIDFV";
SALimitKey const SALimitKeyCarrier = @"SALimitKeyCarrier";


/// is instant event
NSString * const kSAInstantEventKey = @"is_instant_event";
NSString * const kAdsEventKey = @"is_ads_event";

//flush related keys
NSString * const kSAEncryptRecordKeyEKey = @"ekey";
NSString * const kSAEncryptRecordKeyPayloads = @"payloads";
NSString * const kSAEncryptRecordKeyPayload = @"payload";
NSString * const kSAEncryptRecordKeyFlushTime = @"flush_time";
NSString * const kSAEncryptRecordKeyPKV = @"pkv";
NSString * const kSAFlushBodyKeyData = @"data_list";
NSString * const kSAFlushBodyKeyGzip = @"gzip";
NSInteger const kSAFlushGzipCodePlainText = 1;
NSInteger const kSAFlushGzipCodeEncrypt = 9;
NSInteger const kSAFlushGzipCodeTransportEncrypt = 13;

//remote config
NSString * const kSDKConfigKey = @"SASDKConfig";
NSString * const kRequestRemoteConfigRandomTimeKey = @"SARequestRemoteConfigRandomTime";
NSString * const kRandomTimeKey = @"randomTime";
NSString * const kStartDeviceTimeKey = @"startDeviceTime";
NSString * const kSARemoteConfigSupportTransportEncryptKey = @"supportTransportEncrypt";
NSString * const kSARemoteConfigConfigsKey = @"configs";

//SAT Remarketing
NSString * const kSAAppInteractEventTimeIntervalKey = @"appInteract_timestamp";
NSString * const kSAAppInteractEventName = @"$AppInteract";
NSString * const kSAHasTrackInstallation = @"HasTrackInstallation";
NSString * const kSAHasTrackInstallationDisableCallback = @"HasTrackInstallationWithDisableCallback";
NSString * const kSAEventPropertyHasInstalledApp = @"$sat_has_installed_app";
NSString * const kSAEventPropertyAwakeFromDeeplink = @"$sat_awake_from_deeplink";
