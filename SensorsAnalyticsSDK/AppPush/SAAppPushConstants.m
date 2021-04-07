//
// SAAppPushConstants.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/18.
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

#import "SAAppPushConstants.h"

//AppPush Notification related
NSString * const kSAEventNameNotificationClick = @"$AppPushClick";
NSString * const kSAEventPropertyNotificationTitle = @"$app_push_msg_title";
NSString * const kSAEventPropertyNotificationContent = @"$app_push_msg_content";
NSString * const kSAEventPropertyNotificationServiceName = @"$app_push_service_name";
NSString * const kSAEventPropertyNotificationChannel = @"$app_push_channel";
NSString * const kSAEventPropertyNotificationServiceNameLocal = @"Local";
NSString * const kSAEventPropertyNotificationServiceNameJPUSH = @"JPush";
NSString * const kSAEventPropertyNotificationServiceNameGeTui = @"GeTui";
NSString * const kSAEventPropertyNotificationChannelApple = @"Apple";

//identifier for third part push service
NSString * const kSAPushServiceKeyJPUSH = @"_j_business";
NSString * const kSAPushServiceKeyGeTui = @"_ge_";
NSString * const kSAPushServiceKeySF = @"sf_data";

//APNS related key
NSString * const kSAPushAppleUserInfoKeyAps = @"aps";
NSString * const kSAPushAppleUserInfoKeyAlert = @"alert";
NSString * const kSAPushAppleUserInfoKeyTitle = @"title";
NSString * const kSAPushAppleUserInfoKeyBody = @"body";

//sf_data related properties
NSString * const kSFMessageTitle = @"$sf_msg_title";
NSString * const kSFPlanStrategyID = @"$sf_plan_strategy_id";
NSString * const kSFChannelCategory = @"$sf_channel_category";
NSString * const kSFAudienceID = @"$sf_audience_id";
NSString * const kSFChannelID = @"$sf_channel_id";
NSString * const kSFLinkUrl = @"$sf_link_url";
NSString * const kSFPlanType = @"$sf_plan_type";
NSString * const kSFChannelServiceName = @"$sf_channel_service_name";
NSString * const kSFMessageID = @"$sf_msg_id";
NSString * const kSFPlanID = @"$sf_plan_id";
NSString * const kSFStrategyUnitID = @"$sf_strategy_unit_id";
NSString * const kSFEnterPlanTime = @"$sf_enter_plan_time";
NSString * const kSFMessageContent = @"$sf_msg_content";
