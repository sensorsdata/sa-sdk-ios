//  SensorsAnalyticsSDK.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/1.
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

#import <Foundation/Foundation.h>

#import "SensorsAnalyticsSDK+Public.h"
#import "SASecurityPolicy.h"
#import "SAConfigOptions.h"
#import "SAConstants.h"


//SensorsAnalyticsSDK section
#if __has_include("SensorsAnalyticsSDK+SAChannelMatch.h")
#import "SensorsAnalyticsSDK+SAChannelMatch.h"
#endif

#if __has_include("SensorsAnalyticsSDK+DebugMode.h")
#import "SensorsAnalyticsSDK+DebugMode.h"
#endif

#if __has_include("SensorsAnalyticsSDK+Deeplink.h")
#import "SensorsAnalyticsSDK+Deeplink.h"
#endif

#if __has_include("SensorsAnalyticsSDK+SAAutoTrack.h")
#import "SensorsAnalyticsSDK+SAAutoTrack.h"
#endif

#if __has_include("SensorsAnalyticsSDK+Visualized.h")
#import "SensorsAnalyticsSDK+Visualized.h"
#endif

#if __has_include("SASecretKey.h")
#import "SASecretKey.h"
#endif

#if __has_include("SensorsAnalyticsSDK+JavaScriptBridge.h")
#import "SensorsAnalyticsSDK+JavaScriptBridge.h"
#endif

#if __has_include("SensorsAnalyticsSDK+DeviceOrientation.h")
#import "SensorsAnalyticsSDK+DeviceOrientation.h"
#endif

#if __has_include("SensorsAnalyticsSDK+Location.h")
#import "SensorsAnalyticsSDK+Location.h"
#endif


//configOptions section

#if __has_include("SAConfigOptions+RemoteConfig.h")
#import "SAConfigOptions+RemoteConfig.h"
#endif

#if __has_include("SAConfigOptions+Encrypt.h")
#import "SAConfigOptions+Encrypt.h"
#endif

#if __has_include("SAConfigOptions+AppPush.h")
#import "SAConfigOptions+AppPush.h"
#endif

#if __has_include("SAConfigOptions+Exception.h")
#import "SAConfigOptions+Exception.h"
#endif


#if __has_include("SensorsAnalyticsSDK+WKWebView.h")
#import "SensorsAnalyticsSDK+WKWebView.h"
#endif

#if __has_include("SensorsAnalyticsSDK+WebView.h")
#import "SensorsAnalyticsSDK+WebView.h"
#endif
