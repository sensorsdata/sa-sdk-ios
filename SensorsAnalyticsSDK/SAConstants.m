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


#pragma mark - event
NSString * const SA_EVENT_TIME = @"time";
NSString * const SA_EVENT_TRACK_ID = @"_track_id";
NSString * const SA_EVENT_NAME = @"event";
NSString * const SA_EVENT_DISTINCT_ID = @"distinct_id";
NSString * const SA_EVENT_PROPERTIES = @"properties";
NSString * const SA_EVENT_TYPE = @"type";
NSString * const SA_EVENT_LIB = @"lib";
NSString * const SA_EVENT_PROJECT = @"project";
NSString * const SA_EVENT_TOKEN = @"token";
NSString * const SA_EVENT_HYBRID_H5 = @"_hybrid_h5";
NSString * const SA_EVENT_LOGIN_ID = @"login_id";
NSString * const SA_EVENT_ANONYMOUS_ID = @"anonymous_id";

#pragma mark - Item
NSString * const SA_EVENT_ITEM_TYPE = @"item_type";
NSString * const SA_EVENT_ITEM_ID = @"item_id";
NSString * const SA_EVENT_ITEM_SET = @"item_set";
NSString * const SA_EVENT_ITEM_DELETE = @"item_delete";

#pragma mark - event name
// App 启动或激活
NSString * const SA_EVENT_NAME_APP_START = @"$AppStart";
// App 退出或进入后台
NSString * const SA_EVENT_NAME_APP_END = @"$AppEnd";
// App 浏览页面
NSString * const SA_EVENT_NAME_APP_VIEW_SCREEN = @"$AppViewScreen";
// App 元素点击
NSString * const SA_EVENT_NAME_APP_CLICK = @"$AppClick";
// 自动追踪相关事件及属性
NSString * const SA_EVENT_NAME_APP_START_PASSIVELY = @"$AppStartPassively";

NSString * const SA_EVENT_NAME_APP_SIGN_UP = @"$SignUp";

NSString * const SA_EVENT_NAME_APP_CRASHED = @"AppCrashed";
// 远程控制配置变化
NSString * const SA_EVENT_NAME_APP_REMOTE_CONFIG_CHANGED = @"$AppRemoteConfigChanged";

#pragma mark - app install property
NSString * const SA_EVENT_PROPERTY_APP_INSTALL_SOURCE = @"$ios_install_source";
NSString * const SA_EVENT_PROPERTY_APP_INSTALL_DISABLE_CALLBACK = @"$ios_install_disable_callback";
NSString * const SA_EVENT_PROPERTY_APP_USER_AGENT = @"$user_agent";
NSString * const SA_EVENT_PROPERTY_APP_INSTALL_FIRST_VISIT_TIME = @"$first_visit_time";
#pragma mark - autoTrack property
// App 首次启动
NSString * const SA_EVENT_PROPERTY_APP_FIRST_START = @"$is_first_time";
// App 是否从后台恢复
NSString * const SA_EVENT_PROPERTY_RESUME_FROM_BACKGROUND = @"$resume_from_background";
// App 浏览页面 Url
NSString * const SA_EVENT_PROPERTY_SCREEN_URL = @"$url";
// App 浏览页面 Referrer Url
NSString * const SA_EVENT_PROPERTY_SCREEN_REFERRER_URL = @"$referrer";
NSString * const SA_EVENT_PROPERTY_ELEMENT_ID = @"$element_id";
NSString * const SA_EVENT_PROPERTY_SCREEN_NAME = @"$screen_name";
NSString * const SA_EVENT_PROPERTY_TITLE = @"$title";
NSString * const SA_EVENT_PROPERTY_ELEMENT_POSITION = @"$element_position";
NSString * const SA_EVENT_PROPERTY_ELEMENT_SELECTOR = @"$element_selector";
// 模糊路径
NSString * const SA_EVENT_PROPERTY_ELEMENT_PATH = @"$element_path";
NSString * const SA_EVENT_PROPERTY_ELEMENT_CONTENT = @"$element_content";
NSString * const SA_EVENT_PROPERTY_ELEMENT_TYPE = @"$element_type";
NSString * const SA_EVENT_PROPERTY_CHANNEL_INFO = @"$channel_device_info";
NSString * const SA_EVENT_PROPERTY_CHANNEL_CALLBACK_EVENT = @"$is_channel_callback_event";
// 远程控制配置信息
NSString * const SA_EVENT_PROPERTY_APP_REMOTE_CONFIG = @"$app_remote_config";

#pragma mark - common property
NSString * const SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT = @"$project";
NSString * const SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN = @"$token";
NSString * const SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME = @"$time";
//神策成立时间，2015-05-15 10:24:00.000，某些时间戳判断（毫秒）
long long const SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME_INT = 1431656640000;

#pragma mark - profile
NSString * const SA_PROFILE_SET = @"profile_set";
NSString * const SA_PROFILE_SET_ONCE = @"profile_set_once";
NSString * const SA_PROFILE_UNSET = @"profile_unset";
NSString * const SA_PROFILE_DELETE = @"profile_delete";
NSString * const SA_PROFILE_APPEND = @"profile_append";
NSString * const SA_PROFILE_INCREMENT = @"profile_increment";

#pragma mark - NSUserDefaults
NSString * const SA_HAS_LAUNCHED_ONCE = @"HasLaunchedOnce";
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
