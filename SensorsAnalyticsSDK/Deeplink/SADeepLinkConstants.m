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
NSString *const kSAResponsePropertyErrorMessage = @"errorMsg";
NSString *const kSAResponsePropertyErrorMsg = @"error_msg";
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

//dynamic slink related code
NSInteger kSADynamicSlinkStatusCodeSuccess= 0;
NSInteger kSADynamicSlinkStatusCodeLessParams = 10001;
NSInteger kSADynamicSlinkStatusCodeNoNetwork = 10002;
NSInteger kSADynamicSlinkStatusCodeoNoDomain = 10003;
NSInteger kSADynamicSlinkStatusCodeResponseError = 10004;

//dynamic slink event name and properties
NSString *const kSADynamicSlinkEventName = @"$AdDynamicSlinkCreate";
NSString *const kSADynamicSlinkEventPropertyChannelType = @"$ad_dynamic_slink_channel_type";
NSString *const kSADynamicSlinkEventPropertyChannelName = @"$ad_dynamic_slink_channel_name";
NSString *const kSADynamicSlinkEventPropertySource = @"$ad_dynamic_slink_source";
NSString *const kSADynamicSlinkEventPropertyData = @"$ad_dynamic_slink_data";
NSString *const kSADynamicSlinkEventPropertyShortURL = @"$ad_dynamic_slink_short_url";
NSString *const kSADynamicSlinkEventPropertyStatus = @"$ad_dynamic_slink_status";
NSString *const kSADynamicSlinkEventPropertyMessage = @"$ad_dynamic_slink_msg";
NSString *const kSADynamicSlinkEventPropertyID = @"$ad_slink_id";
NSString *const kSADynamicSlinkEventPropertyTemplateID = @"$ad_slink_template_id";
NSString *const kSADynamicSlinkEventPropertyType = @"$ad_slink_type";
NSString *const kSADynamicSlinkEventPropertyTypeDynamic = @"dynamic";

//dynamic slink API path
NSString *const kSADynamicSlinkAPIPath = @"slink/dynamic/links";

//dynamic slink API params
NSString *const kSADynamicSlinkParamProject = @"project_name";
NSString *const kSADynamicSlinkParamTemplateID = @"slink_template_id";
NSString *const kSADynamicSlinkParamType = @"slink_type";
NSString *const kSADynamicSlinkParamName = @"name";
NSString *const kSADynamicSlinkParamChannelType = @"channel_type";
NSString *const kSADynamicSlinkParamChannelName = @"channel_name";
NSString *const kSADynamicSlinkParamFixedUTM = @"fixed_param";
NSString *const kSADynamicSlinkParamUTMSource = @"channel_utm_source";
NSString *const kSADynamicSlinkParamUTMCampaign = @"channel_utm_campaign";
NSString *const kSADynamicSlinkParamUTMMedium = @"channel_utm_medium";
NSString *const kSADynamicSlinkParamUTMTerm = @"channel_utm_term";
NSString *const kSADynamicSlinkParamUTMContent = @"channel_utm_content";
NSString *const kSADynamicSlinkParamCustom = @"custom_param";
NSString *const kSADynamicSlinkParamRoute = @"route_param";
NSString *const kSADynamicSlinkParamURIScheme = @"uri_scheme_suffix";
NSString *const kSADynamicSlinkParamLandingPageType = @"landing_page_type";
NSString *const kSADynamicSlinkParamLandingPage = @"other_landing_page_map";
NSString *const kSADynamicSlinkParamJumpAddress = @"jump_address";

