//
// SAVisualizedResources.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2023/1/16.
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

#import "SAVisualizedResources.h"

@implementation SAVisualizedResources

+ (NSString *)visualizedPath {
    return @"{\"type\":\"snapshot_request\",\"payload\":{\"config\":{\"classes\":[{\"name\":\"NSObject\",\"superclass\":null,\"properties\":[]},{\"name\":\"UIScreen\",\"superclass\":\"NSObject\",\"properties\":[{\"name\":\"bounds\",\"type\":\"CGRect\",\"readonly\":true},{\"name\":\"applicationFrame\",\"type\":\"CGRect\",\"readonly\":true}]},{\"name\":\"UIView\",\"superclass\":\"UIResponder\",\"properties\":[{\"name\":\"sensorsdata_enableAppClick\",\"key\":\"enableAppClick\",\"type\":\"BOOL\",\"use_kvc\":false},{\"name\":\"sensorsdata_subElements\",\"key\":\"subelements\",\"type\":\"NSArray\",\"use_kvc\":false},{\"name\":\"sensorsdata_elementValidContent\",\"key\":\"element_content\",\"type\":\"NSString\",\"use_kvc\":false},{\"name\":\"sensorsdata_elementPath\",\"key\":\"element_path\",\"type\":\"NSString\",\"use_kvc\":false},{\"name\":\"sensorsdata_elementPosition\",\"key\":\"element_position\",\"type\":\"NSString\",\"use_kvc\":false},{\"name\":\"sensorsdata_frame\",\"key\":\"frame\",\"type\":\"CGRect\",\"use_kvc\":false},{\"name\":\"jjf_fingerprintVersion\",\"type\":\"NSString\",\"use_kvc\":false},{\"name\":\"sensorsAnalyticsViewID\",\"type\":\"NSString\",\"use_kvc\":false},{\"name\":\"restorationIdentifier\",\"type\":\"NSString\"},{\"name\":\"sensorsdata_screenName\",\"key\":\"screen_name\",\"type\":\"NSString\",\"use_kvc\":false},{\"name\":\"sensorsdata_title\",\"key\":\"title\",\"type\":\"NSString\",\"use_kvc\":false},{\"name\":\"sensorsdata_isFromWeb\",\"key\":\"is_h5\",\"type\":\"BOOL\",\"use_kvc\":false},{\"name\":\"sensorsdata_isListView\",\"key\":\"is_list_view\",\"type\":\"BOOL\",\"use_kvc\":false},{\"name\":\"sensorsdata_platform\",\"key\":\"element_platform\",\"type\":\"NSString\",\"use_kvc\":false}]},{\"name\":\"SAWebElementView\",\"superclass\":\"UIView\",\"properties\":[{\"name\":\"url\",\"type\":\"NSString\"},{\"name\":\"title\",\"key\":\"h5_title\",\"type\":\"NSString\"},{\"name\":\"tagName\",\"key\":\"tag_name\",\"type\":\"NSString\"},{\"name\":\"listSelector\",\"key\":\"list_selector\",\"type\":\"NSString\"},{\"name\":\"sensorsdata_elementSelector\",\"key\":\"element_selector\",\"type\":\"NSString\",\"use_kvc\":false}]},{\"name\":\"SAFlutterElementView\",\"superclass\":\"UIView\"},{\"name\":\"UIScrollView\",\"superclass\":\"UIView\",\"properties\":[{\"name\":\"contentOffset\",\"type\":\"CGPoint\"},{\"name\":\"contentSize\",\"type\":\"CGSize\"}]},{\"name\":\"UIViewController\",\"superclass\":\"UIResponder\",\"properties\":[{\"name\":\"sensorsdata_subElements\",\"key\":\"subelements\",\"type\":\"NSArray\",\"use_kvc\":false},{\"name\":\"restorationIdentifier\",\"type\":\"NSString\"}]}]}}}";
}

@end
