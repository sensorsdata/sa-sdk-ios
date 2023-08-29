//
// SACoreResources+English.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2023/8/22.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
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

#import "SACoreResources+English.h"

@implementation SACoreResources (English)

+ (NSDictionary *)englishLanguageResources {
    return @{
        @"SADebugMode": @"SDK Debug Mode",
        @"SADebugOnly": @"DEBUG_ONLY",
        @"SADebugAndTrack": @"DEBUG_AND_TRACK",
        @"SADebugOff": @"DEBUG_OFF",
        @"SADebugCurrentlyInDebugOnly": @"Currently in DEBUG_ONLY mode (don't import data)",
        @"SADebugCurrentlyInDebugAndTrack": @"Currently in DEBUG_AND_TRACK mode (import data)",
        @"SADebugModeTurnedOff": @"The debug mode has been turned off, please scan the QR code again to turn it on",
        @"SADebugOnlyModeTurnedOn": @"Turn on the debug mode, verify the data, but do not import the data;\nAfter the App process is closed, the debug mode will be automatically turned off.",
        @"SADebugAndTrackModeTurnedOn": @"Turn on the debug mode, verify the data, and import the data into Sensors Analysis;\nAfter the App process is closed, the debug mode will be automatically turned off.",
        @"SADebugNowInDebugOnlyMode": @"Now you have turned on the 'DEBUG_ONLY' mode. In this mode, only the data is verified but not imported. When the data is wrong, the developer will be prompted by alert. Please turn it off before you go online.",
        @"SADebugNowInDebugAndTrackMode": @"Now you have turned on the 'DEBUG_AND_TRACK' mode. In this mode, data is verified and imported. When the data is wrong, the developer will be prompted by alert. Please turn it off before you go online.",
        @"SADebugNotes": @"SensorsData Important Notes",
        @"SAVisualizedConnect": @"Connecting to Visualized AutoTrack",
        @"SAVisualizedWifi": @", it is recommended to use it in a WiFi environment",
        @"SAVisualizedProjectError": @"The App's project is different from the computer browser, and Visualized AutoTrack is not available",
        @"SAVisualizedEnableLogHint": @"To enter the Debug mode with the Visualized AutoTrack, you need to enable log printing to collect debugging information, and exit the Debug mode to close the log printing. Do you need to enable it?",
        @"SAVisualizedEnableLogAction": @"Enable Log",
        @"SAVisualizedTemporarilyDisabled": @"Temporarily Disabled",
        @"SAVisualizedPageErrorTitle": @"The current page cannot use Visualized AutoTrack",
        @"SAVisualizedPageErrorMessage": @"This page is not a WKWebView, the iOS App embedded H5 Visualized AutoTrack, only supports WKWebView",
        @"SAVisualizedConfigurationDocument": @"Configuration Document",
        @"SAVisualizedJSError": @"This page is not integrated with the Web JS SDK or the version of the Web JS SDK is too low, please integrate the latest version of the Web JS SDK",
        @"SAVisualizedSDKError": @"The SDK is not integrated correctly, please contact your technical staff to enable Visualized AutoTrack",
        @"SAVisualizedParameterError": @"parameter error",
        @"SAVisualizedAutoTrack": @"Visualized AutoTrack",
        @"SAAppClicksAnalyticsConnect": @"Connecting to App Clicks Analytics",
        @"SAAppClicksAnalyticsSDKError": @"The SDK is not integrated correctly, please contact your technical staff to enable App Clicks Analytics",
        @"SAAppClicksAnalyticsProjectError": @"The App's project is different from the computer browser, and App Clicks Analytics is not available",
        @"SAAppClicksAnalyticsPageErrorTitle": @"The current page cannot use App Clicks Analytics",
        @"SAAppClicksAnalyticsPageErrorMessage": @"This page contains UIWebView, the iOS App embedded H5 App Clicks Analytics, only supports WKWebView",
        @"SAAppClicksAnalytics": @"App Clicks Analytics",
        @"SARemoteConfigStart": @"Start get remote config",
        @"SARemoteConfigObtainFailed": @"Failed to obtain remote config, please scan the QR code again later",
        @"SARemoteConfigProjectError": @"The project integrated by the app is different from the project corresponding to the QR code, and cannot be debugged",
        @"SARemoteConfigOSError": @"The operating system corresponding to the App and the QR code is different and cannot be debugged",
        @"SARemoteConfigAppError": @"The app is different from the app corresponding to the QR code and cannot be debugged",
        @"SARemoteConfigQRError": @"QR code information verification failed, please check whether the remote config is configured correctly",
        @"SARemoteConfigNetworkError": @"Network connected fails, please scan the QR code again for debugging",
        @"SARemoteConfigWrongVersion": @"Wrong Version",
        @"SARemoteConfigLoaded": @"The remote config is loaded and can be debugged through the Xcode console log",
        @"SARemoteConfigCompareVersion": @"The version from the url: %@, the version from the QR code: %@, please scan the QR code again later",
        @"SAEncryptSelectedKeyInvalid": @"Key verification failed, the selected key is invalid",
        @"SAEncryptNotEnabled": @"Encryption is not enabled in the current app, please enable encryption and try again",
        @"SAEncryptAppKeyEmpty": @"The key verification fails, and the App-side key is empty",
        @"SAEncryptKeyVerificationPassed": @"The key verification is passed, and the selected key is the same as the App-side key",
        @"SAEncryptKeyTypeVerificationFailed": @"The key verification failed, and the selected key type is different from the app-side key type. Selected key symmetric algorithm type: %@, asymmetricEncryptType: %@, App-side key symmetric algorithm type: %@, asymmetricEncryptType: %@",
        @"SAEncryptKeyVersionVerificationFailed": @"The key verification failed, the selected key is not the same as the app-side key. Selected key version: %@, App-side key version: %@",
        @"SAChannelReconnectError": @"It cannot be reconnected. Please check whether the phone has been replaced",
        @"SAChannelServerURLError": @"The ServerURL is incorrect. The joint diagnostic tool cannot be used",
        @"SAChannelProjectError": @"The project integrated by App is different from the project opened by computer browser, and the joint diagnostic tool cannot be used",
        @"SAChannelEnableJointDebugging": @"Enable joint debugging mode",
        @"SAChannelNetworkError": @"The current network is unavailable, please check the network!",
        @"SAChannelRequestWhitelistFailed": @"Failed to add whitelist request, please contact SensorsData technical support personnel to troubleshoot the problem!",
        @"SAChannelSuccessfullyEnabled": @"Successfully enabled joint debugging mode",
        @"SAChannelTriggerActivation": @"In this mode, there is no need to uninstall the App. Click the \"Activate\" button to trigger the activation repeatedly.",
        @"SAChannelActivate": @"Activate",
        @"SAChannelDeviceCodeEmpty": @"The \"device code is empty\" is detected, the possible reasons are as follows, please check:",
        @"SAChannelTroubleshooting": @"\n1.「Privacy -> Advertising -> Limit Ad Tracking」 in the phone system settings;\n\n2.If the mobile phone system is iOS 14, please contact the developer to confirm whether the trackAppInstall interface is called after the \"tracking\" authorization.\n\nAfter troubleshooting, please scan the code again for joint debugging.\n\n",
        @"SAChannelNetworkException": @"Network exception, request failed!",
        @"SADeepLinkCallback": @"The callback function is not set by calling the setDeepLinkCompletion method",
        @"SAAlertCancel": @"Cancel",
        @"SAAlertContinue": @"Continue",
        @"SAAlertHint": @"Hint",
        @"SAAlertOK": @"OK",
        @"SAAlertNotRemind": @"Don't Remind",
        @"SAPresetPropertyCarrierMobile": @"MOBILE",
        @"SAPresetPropertyCarrierUnicom": @"UNICOM",
        @"SAPresetPropertyCarrierTelecom": @"TELECOM",
        @"SAPresetPropertyCarrierSatellite": @"SATELLITE",
        @"SAPresetPropertyCarrierTietong": @"TIETONG"
    };
}

@end
