//
// SADeepLinkConstants.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/12/10.
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

#import <Foundation/Foundation.h>

#pragma mark - Event Name

NSString *const kSAAppDeepLinkLaunchEvent = @"$AppDeeplinkLaunch";
NSString *const kSADeepLinkMatchedResultEvent = @"$AppDeeplinkMatchedResult";
NSString *const kSADeferredDeepLinkJumpEvent = @"$AdAppDeferredDeepLinkJump";

#pragma mark - Other
NSString *const kSADeepLinkLatestChannelsFileName = @"latest_utms";
NSString *const kSADeferredDeepLinkStatus = @"RequestDeferredDeepLinkStatus";

#pragma mark - Event Property
NSString *const kSAEventPropertyDeepLinkURL = @"$deeplink_url";
NSString *const kSAEventPropertyDeepLinkOptions = @"$deeplink_options";
NSString *const kSAEventPropertyDeepLinkFailReason = @"$deeplink_match_fail_reason";
NSString *const kSAEventPropertyDuration = @"$event_duration";
NSString *const kSAEventPropertyADMatchType = @"$ad_app_match_type";
NSString *const kSAEventPropertyADDeviceInfo = @"$ad_device_info";
NSString *const kSAEventPropertyADChannel= @"$ad_deeplink_channel_info";
NSString *const kSAEventPropertyADSLinkID = @"$ad_slink_id";

#pragma mark - Request Property
NSString *const kSARequestPropertyUserAgent = @"$user_agent";

NSString *const kSARequestPropertyIDs = @"ids";
NSString *const kSARequestPropertyUA = @"ua";
NSString *const kSARequestPropertyOS = @"os";
NSString *const kSARequestPropertyOSVersion = @"os_version";
NSString *const kSARequestPropertyModel = @"model";
NSString *const kSARequestPropertyNetwork = @"network";
NSString *const kSARequestPropertyTimestamp = @"timestamp";
NSString *const kSARequestPropertyAppID = @"app_id";
NSString *const kSARequestPropertyAppVersion = @"app_version";
NSString *const kSARequestPropertyAppParameter = @"app_parameter";
NSString *const kSARequestPropertyProject = @"project";

#pragma mark - Response Property

NSString *const kSAResponsePropertyCode = @"code";
NSString *const kSAResponsePropertyMessage = @"msg";

NSString *const kSAResponsePropertySLinkID = @"ad_slink_id";

// DeepLink
NSString *const kSAResponsePropertyParams = @"page_params";
NSString *const kSAResponsePropertyChannelParams = @"channel_params";

// Deferred DeepLink
NSString *const kSAResponsePropertyParameter = @"parameter";
NSString *const kSAResponsePropertyADChannel = @"ad_channel";


NSSet* sensorsdata_preset_channel_keys(void) {
    return [NSSet setWithObjects:@"utm_campaign", @"utm_content", @"utm_medium", @"utm_source", @"utm_term", nil];
}
