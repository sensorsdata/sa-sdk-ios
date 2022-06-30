//
// SAPropertyInterceptor.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/13.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAPropertyInterceptor.h"
#import "SAPropertyPluginManager.h"
#import "SAModuleManager.h"
#import "SAConstants+Private.h"
#import "SACustomPropertyPlugin.h"
#import "SASuperPropertyPlugin.h"
#import "SADeviceIDPropertyPlugin.h"
#import "SALog.h"

@implementation SAPropertyInterceptor

- (void)processWithInput:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);

    // 注册自定义属性采集插件，采集 track 附带属性

    SACustomPropertyPlugin *customPlugin = [[SACustomPropertyPlugin alloc] initWithCustomProperties:input.properties];
    [[SAPropertyPluginManager sharedInstance] registerCustomPropertyPlugin:customPlugin];
    input.properties = nil;

    SABaseEventObject *object = input.eventObject;
    // 获取插件采集的所有属性
    NSMutableDictionary *properties = [[SAPropertyPluginManager sharedInstance] propertiesWithFilter:object];

    // 事件、公共属性和动态公共属性都需要支持修改 $project, $token, $time
    object.project = (NSString *)properties[kSAEventCommonOptionalPropertyProject];
    object.token = (NSString *)properties[kSAEventCommonOptionalPropertyToken];
    id originalTime = properties[kSAEventCommonOptionalPropertyTime];

    // App 内嵌 H5 自定义 time 在初始化中单独处理
    if ([originalTime isKindOfClass:NSDate.class] && !object.hybridH5) {
        NSDate *customTime = (NSDate *)originalTime;
        int64_t customTimeInt = [customTime timeIntervalSince1970] * 1000;
        if (customTimeInt >= kSAEventCommonOptionalPropertyTimeInt) {
            object.time = customTimeInt;
        } else {
            SALogError(@"$time error %lld, Please check the value", customTimeInt);
        }
    } else if (originalTime && !object.hybridH5) {
        SALogError(@"$time '%@' invalid, Please check the value", originalTime);
    }

    // $project, $token, $time 处理完毕后需要移除
    NSArray<NSString *> *needRemoveKeys = @[kSAEventCommonOptionalPropertyProject,
                                            kSAEventCommonOptionalPropertyToken,
                                            kSAEventCommonOptionalPropertyTime];
    [properties removeObjectsForKeys:needRemoveKeys];

    // 公共属性, 动态公共属性, 自定义属性不允许修改 $anonymization_id、$device_id 属性, 因此需要将修正逻操作放在所有属性添加后
    if (input.configOptions.disableDeviceId) {
        // 不允许客户设置 $device_id
        [properties removeObjectForKey:kSADeviceIDPropertyPluginDeviceID];
    } else {
        // 不允许客户设置 $anonymization_id
        [properties removeObjectForKey:kSADeviceIDPropertyPluginAnonymizationID];
    }

    [object.properties addEntriesFromDictionary:[properties copy]];

    // 从公共属性中更新 lib 节点中的 $app_version 值
    NSDictionary *superProperties = [SAPropertyPluginManager.sharedInstance currentPropertiesForPluginClasses:@[SASuperPropertyPlugin.class]];
    id appVersion = superProperties[kSAEventPresetPropertyAppVersion];
    if (appVersion) {
        object.lib.appVersion = appVersion;
    }

    // 仅在全埋点的元素点击和页面浏览事件中添加 $lib_detail
    BOOL isAppClick = [object.event isEqualToString:kSAEventNameAppClick];
    BOOL isViewScreen = [object.event isEqualToString:kSAEventNameAppViewScreen];
    NSDictionary *customProperties = [customPlugin properties];
    if (isAppClick || isViewScreen) {
        object.lib.detail = [NSString stringWithFormat:@"%@######", customProperties[kSAEventPropertyScreenName] ?: @""];
    }

    completion(input);
}

@end
