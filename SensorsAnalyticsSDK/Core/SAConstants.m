//
//  SAConstants.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/9.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAConstants.h"
#import "SAConstants+Private.h"

#pragma mark - Track Timer
NSString *const kSAEventIdSuffix = @"_SATimer";

#pragma mark - event
NSString * const kSAEventTime = @"time";
NSString * const kSAEventTrackId = @"_track_id";
NSString * const kSAEventName = @"event";
NSString * const kSAEventDistinctId = @"distinct_id";
NSString * const kSAEventProperties = @"properties";
NSString * const kSAEventType = @"type";
NSString * const kSAEventLib = @"lib";
NSString * const kSAEventProject = @"project";
NSString * const kSAEventToken = @"token";
NSString * const kSAEventHybridH5 = @"_hybrid_h5";
NSString * const kSAEventLoginId = @"login_id";
NSString * const kSAEventAnonymousId = @"anonymous_id";

#pragma mark - Item
NSString * const SA_EVENT_ITEM_TYPE = @"item_type";
NSString * const SA_EVENT_ITEM_ID = @"item_id";
NSString * const SA_EVENT_ITEM_SET = @"item_set";
NSString * const SA_EVENT_ITEM_DELETE = @"item_delete";

#pragma mark - event name
// App 启动或激活
NSString * const kSAEventNameAppStart = @"$AppStart";
// App 退出或进入后台
NSString * const kSAEventNameAppEnd = @"$AppEnd";
// App 浏览页面
NSString * const kSAEventNameAppViewScreen = @"$AppViewScreen";
// App 元素点击
NSString * const kSAEventNameAppClick = @"$AppClick";
// 自动追踪相关事件及属性
NSString * const kSAEventNameAppStartPassively = @"$AppStartPassively";

NSString * const kSAEventNameSignUp = @"$SignUp";

NSString * const kSAEventNameAppCrashed = @"AppCrashed";
// 远程控制配置变化
NSString * const kSAEventNameAppRemoteConfigChanged = @"$AppRemoteConfigChanged";

#pragma mark - app install property
NSString * const SA_EVENT_PROPERTY_APP_INSTALL_SOURCE = @"$ios_install_source";
NSString * const SA_EVENT_PROPERTY_APP_INSTALL_DISABLE_CALLBACK = @"$ios_install_disable_callback";
NSString * const SA_EVENT_PROPERTY_APP_INSTALL_FIRST_VISIT_TIME = @"$first_visit_time";
#pragma mark - autoTrack property
// App 浏览页面 Url
NSString * const kSAEventPropertyScreenUrl = @"$url";
// App 浏览页面 Referrer Url
NSString * const kSAEventPropertyScreenReferrerUrl = @"$referrer";
NSString * const kSAEventPropertyElementId = @"$element_id";
NSString * const kSAEventPropertyScreenName = @"$screen_name";
NSString * const kSAEventPropertyTitle = @"$title";
NSString * const kSAEventPropertyElementPosition = @"$element_position";
NSString * const kSAEventPropertyElementSelector = @"$element_selector";

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

#pragma mark - profile
NSString * const SA_PROFILE_SET = @"profile_set";
NSString * const SA_PROFILE_SET_ONCE = @"profile_set_once";
NSString * const SA_PROFILE_UNSET = @"profile_unset";
NSString * const SA_PROFILE_DELETE = @"profile_delete";
NSString * const SA_PROFILE_APPEND = @"profile_append";
NSString * const SA_PROFILE_INCREMENT = @"profile_increment";

#pragma mark - NSUserDefaults
NSString * const SA_HAS_TRACK_INSTALLATION = @"HasTrackInstallation";
NSString * const SA_HAS_TRACK_INSTALLATION_DISABLE_CALLBACK = @"HasTrackInstallationWithDisableCallback";

#pragma mark - bridge name
NSString * const SA_SCRIPT_MESSAGE_HANDLER_NAME = @"sensorsdataNativeTracker";

NSSet* sensorsdata_reserved_properties() {
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

#pragma mark - SF related notifications
NSNotificationName const SA_TRACK_EVENT_NOTIFICATION = @"SensorsAnalyticsTrackEventNotification";
NSNotificationName const SA_TRACK_LOGIN_NOTIFICATION = @"SensorsAnalyticsTrackLoginNotification";
NSNotificationName const SA_TRACK_LOGOUT_NOTIFICATION = @"SensorsAnalyticsTrackLogoutNotification";
NSNotificationName const SA_TRACK_IDENTIFY_NOTIFICATION = @"SensorsAnalyticsTrackIdentifyNotification";
NSNotificationName const SA_TRACK_RESETANONYMOUSID_NOTIFICATION = @"SensorsAnalyticsTrackResetAnonymousIdNotification";
NSNotificationName const SA_TRACK_EVENT_H5_NOTIFICATION = @"SensorsAnalyticsTrackEventFromH5Notification";

#pragma mark - ABTest related notifications
NSNotificationName const SA_H5_BRIDGE_NOTIFICATION = @"SensorsAnalyticsRegisterJavaScriptBridgeNotification";

NSNotificationName const SA_H5_MESSAGE_NOTIFICATION = @"SensorsAnalyticsMessageFromH5Notification";

#pragma mark - other
// 远程配置更新
NSNotificationName const SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION = @"cn.sensorsdata.SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION";

// App 内嵌 H5 接收可视化相关 H5 页面元素信息
NSNotificationName const SA_VISUALIZED_H5_MESSAGE_NOTIFICATION = @"SensorsAnalyticsVisualizedMessageFromH5Notification";

//page leave
NSString * const kSAPageLeaveTimestamp = @"timestamp";
NSString * const kSAPageLeaveAutoTrackProperties = @"properties";
NSString * const kSAEventDurationProperty = @"event_duration";
NSString * const kSAEventNameAppPageLeave = @"$AppPageLeave";
