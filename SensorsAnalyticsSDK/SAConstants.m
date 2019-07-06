//
//  SAConstants.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/9.
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

#import "SAConstants.h"
#import "SAConstants+Private.h"


#pragma mark - event
NSString * const SA_EVENT_TIME = @"time";
NSString * const SA_EVENT_TRACK_ID = @"_track_id";
NSString * const SA_EVENT_NAME = @"event";
NSString * const SA_EVENT_FLUSH_TIME = @"_flush_time";
NSString * const SA_EVENT_DISTINCT_ID = @"distinct_id";
NSString * const SA_EVENT_PROPERTIES = @"properties";
NSString * const SA_EVENT_TYPE = @"type";
NSString * const SA_EVENT_LIB = @"lib";
NSString * const SA_EVENT_PROJECT = @"project";
NSString * const SA_EVENT_TOKEN = @"token";

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

#pragma mark - app install property
NSString * const SA_EVENT_PROPERTY_APP_INSTALL_SOURCE = @"$ios_install_source";
NSString * const SA_EVENT_PROPERTY_APP_INSTALL_DISABLE_CALLBACK = @"$ios_install_disable_callback";
NSString * const SA_EVENT_PROPERTY_APP_INSTALL_USER_AGENT = @"$user_agent";
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
NSString * const SA_EVENT_PROPERTY_ELEMENT_CONTENT = @"$element_content";
NSString * const SA_EVENT_PROPERTY_ELEMENT_TYPE = @"$element_type";

#pragma mark - common property
NSString * const SA_EVENT_COMMON_PROPERTY_LIB = @"$lib";
NSString * const SA_EVENT_COMMON_PROPERTY_LIB_VERSION = @"$lib_version";
NSString * const SA_EVENT_COMMON_PROPERTY_LIB_DETAIL = @"$lib_detail";
NSString * const SA_EVENT_COMMON_PROPERTY_LIB_METHOD = @"$lib_method";

NSString * const SA_EVENT_COMMON_PROPERTY_APP_VERSION = @"$app_version";
NSString * const SA_EVENT_COMMON_PROPERTY_MODEL =@"$model";
NSString * const SA_EVENT_COMMON_PROPERTY_MANUFACTURER = @"$manufacturer";
NSString * const SA_EVENT_COMMON_PROPERTY_OS = @"$os";
NSString * const SA_EVENT_COMMON_PROPERTY_OS_VERSION = @"$os_version";
NSString * const SA_EVENT_COMMON_PROPERTY_SCREEN_HEIGHT = @"$screen_height";
NSString * const SA_EVENT_COMMON_PROPERTY_SCREEN_WIDTH = @"$screen_width";
NSString * const SA_EVENT_COMMON_PROPERTY_NETWORK_TYPE = @"$network_type";
NSString * const SA_EVENT_COMMON_PROPERTY_WIFI = @"$wifi";
NSString * const SA_EVENT_COMMON_PROPERTY_CARRIER = @"$carrier";
NSString * const SA_EVENT_COMMON_PROPERTY_DEVICE_ID = @"$device_id";
NSString * const SA_EVENT_COMMON_PROPERTY_IS_FIRST_DAY = @"$is_first_day";


NSString * const SA_EVENT_COMMON_OPTIONAL_PROPERTY_LATITUDE = @"$latitude";
NSString * const SA_EVENT_COMMON_OPTIONAL_PROPERTY_LONGITUDE = @"$longitude";
NSString * const SA_EVENT_COMMON_OPTIONAL_PROPERTY_SCREEN_ORIENTATION = @"$screen_orientation";

NSString * const SA_EVENT_COMMON_OPTIONAL_PROPERTY_APP_STATE = @"$app_state";

NSString * const SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT = @"$project";
NSString * const SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN = @"$token";
NSString * const SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME = @"$time";
//神策成立时间，2015-05-15 10:24:00.000，某些时间戳判断（毫秒）
long const SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME_INT = 1431656640000;

#pragma mark - profile
NSString * const SA_PROFILE_SET = @"profile_set";
NSString * const SA_PROFILE_SET_ONCE = @"profile_set_once";
NSString * const SA_PROFILE_UNSET = @"profile_unset";
NSString * const SA_PROFILE_DELETE = @"profile_delete";
NSString * const SA_PROFILE_APPEND = @"profile_append";
NSString * const SA_PROFILE_INCREMENT = @"profile_increment";

#pragma mark - NSUserDefaults
NSString * const SA_SDK_TRACK_CONFIG = @"SASDKConfig";
///保存请求远程配置的随机时间 @{@"randomTime":@double,@“startDeviceTime”:@double}
NSString * const SA_REQUEST_REMOTECONFIG_TIME = @"SARequestRemoteConfigRandomTime";

NSString * const SA_HAS_LAUNCHED_ONCE = @"HasLaunchedOnce";
NSString * const SA_HAS_TRACK_INSTALLATION = @"HasTrackInstallation";
NSString * const SA_HAS_TRACK_INSTALLATION_DISABLE_CALLBACK = @"HasTrackInstallationWithDisableCallback";


void sensorsdata_dispatch_main_safe_sync(DISPATCH_NOESCAPE dispatch_block_t block) {
    sensorsdata_dispatch_safe_sync(dispatch_get_main_queue(),block);
}

void sensorsdata_dispatch_safe_sync(dispatch_queue_t queue,DISPATCH_NOESCAPE dispatch_block_t block) {
    if ((dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)) == dispatch_queue_get_label(queue)) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}
