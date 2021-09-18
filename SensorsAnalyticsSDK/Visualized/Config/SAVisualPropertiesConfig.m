//
// SAVisualPropertiesConfig.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/6.
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

#import "SAVisualPropertiesConfig.h"
#import "UIView+SAElementPath.h"
#import "SAVisualizedUtils.h"
#import "UIView+AutoTrack.h"
#import "SAValidator.h"
#import "SAViewNode.h"

static id dictionaryValueForKey(NSDictionary *dic, NSString *key) {
    if (![SAValidator isValidDictionary:dic]) {
        return nil;
    }

    id value = dic[key];
    return (value && ![value isKindOfClass:NSNull.class]) ? value : nil;
}

@implementation SAViewIdentifier

- (instancetype)initWithDictionary:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        _elementPath = dictionaryValueForKey(dic, @"element_path");
        _screenName = dictionaryValueForKey(dic, @"screen_name");
        _elementPosition = dictionaryValueForKey(dic, @"element_position");
        _elementContent = dictionaryValueForKey(dic, @"element_content");
        _pageIndex = -1;
    }
    return self;
}

- (instancetype)initWithView:(UIView *)view {
    self = [super init];
    if (self) {
        _elementPath = view.sensorsdata_elementPath;
        _screenName = view.sensorsdata_screenName;
        _elementContent = view.sensorsdata_elementContent;
        _elementPosition = view.sensorsdata_elementPosition;
        _pageIndex = [SAVisualizedUtils pageIndexWithView:view];
    }
    return self;
}

// view 路径是否相同
- (BOOL)isEqualToViewIdentify:(SAViewIdentifier *)object {
    BOOL sameElementPath = [self.elementPath isEqualToString:object.elementPath];
    BOOL sameScreenName = [self.screenName isEqualToString:object.screenName];
    return sameElementPath && sameScreenName;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.elementPath forKey:@"elementPath"];
    [coder encodeObject:self.screenName forKey:@"screenName"];
    [coder encodeObject:self.elementPosition forKey:@"elementPosition"];
    [coder encodeObject:self.elementContent forKey:@"elementContent"];
    [coder encodeInteger:self.pageIndex forKey:@"pageIndex"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.elementPath = [coder decodeObjectForKey:@"elementPath"];
        self.screenName = [coder decodeObjectForKey:@"screenName"];
        self.elementPosition = [coder decodeObjectForKey:@"elementPosition"];
        self.elementContent = [coder decodeObjectForKey:@"elementContent"];
        self.pageIndex = [coder decodeIntegerForKey:@"pageIndex"];
    }
    return self;
}

@end

@implementation SAVisualPropertiesEventConfig

- (instancetype)initWithDictionary:(NSDictionary *)eventDic {
    self = [super initWithDictionary:eventDic];
    if (self) {
        _limitPosition = [dictionaryValueForKey(eventDic, @"limit_element_position") boolValue];
        _limitContent = [dictionaryValueForKey(eventDic, @"limit_element_content") boolValue];
        _h5 = [dictionaryValueForKey(eventDic, @"h5") boolValue];
    }
    return self;
}

- (BOOL)isMatchVisualEventWithViewIdentify:(SAViewIdentifier *)viewIdentify {
    if (![self isEqualToViewIdentify:viewIdentify]) {
        return NO;
    }
    // 匹配元素位置
    if (self.limitPosition && ![self.elementPosition isEqualToString:viewIdentify.elementPosition]) {
        return NO;
    }
    
    // 匹配元素内容
    if (self.limitContent && ![self.elementContent isEqualToString:viewIdentify.elementContent]) {
        return NO;
    }
    return YES;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeBool:self.limitPosition forKey:@"limitPosition"];
    [coder encodeBool:self.limitContent forKey:@"limitContent"];
    [coder encodeBool:self.isH5 forKey:@"h5"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.limitPosition = [coder decodeBoolForKey:@"limitPosition"];
        self.limitContent = [coder decodeBoolForKey:@"limitContent"];
        self.h5 = [coder decodeBoolForKey:@"h5"];
    }
    return self;
}

@end


@implementation SAVisualPropertiesPropertyConfig

- (instancetype)initWithDictionary:(NSDictionary *)propertiesDic {
    self = [super initWithDictionary:propertiesDic];
    if (self) {
        _name = dictionaryValueForKey(propertiesDic, @"name");
        _regular = dictionaryValueForKey(propertiesDic, @"regular");
        NSString *type = dictionaryValueForKey(propertiesDic, @"type");
        if ([type isEqualToString:@"NUMBER"]) {
            _type = SAVisualPropertyTypeNumber;
        } else {
            _type = SAVisualPropertyTypeString;
        }

        _h5 = [dictionaryValueForKey(propertiesDic, @"h5") boolValue];
        // h5 属性对应的 webview 路径
        _webViewElementPath = dictionaryValueForKey(propertiesDic, @"webview_element_path");
    }
    return self;
}

/// 当前属性配置，是否命中元素
- (BOOL)isMatchVisualPropertiesWithViewIdentify:(SAViewIdentifier *)viewIdentify {
    BOOL isEqualToIdentify = NO;
    // H5 属性配置，只用于查询 weView，单独判断
    if (self.isH5) {
        isEqualToIdentify = [self isEqualToWebViewIdentify:viewIdentify];
    } else {
        isEqualToIdentify = [self isEqualToViewIdentify:viewIdentify];
    }
    if (!isEqualToIdentify) {
        return NO;
    }

    // 对比页面 pageIndex
    BOOL enableMatchPageIndex = self.pageIndex >= 0 && viewIdentify.pageIndex >= 0;
    if (enableMatchPageIndex && self.pageIndex != viewIdentify.pageIndex) {
        return NO;
    }
    // H5 配置，只用于查询 weView，不能比较 App 元素位置
    if (self.isH5) {
        return YES;
    }

    /* 属性元素，位置匹配场景
     1. 属性元素为列表，事件元素为列表
     a. 事件限定位置，属性元素位置和属性配置位置匹配
     b. 事件不限位置，属性元素位置，和事件点击元素位置匹配 ⭐️
     2. 属性元素为列表，事件如果为非列表，属性元素位置和属性配置位置匹配
     3. 属性元素非列表，那事件一定不是列表，直接匹配 path 和 screenName 即可
     */
    if (self.elementPosition.length == 0) { // 属性元素非列表
        return YES;
    }

    // 事件元素为列表，且不限元素位置，此时和点击元素位置匹配
    if (self.clickElementPosition.length > 0) { // 事件元素为列表
        if (self.isLimitPosition) { // 限定元素位置
            return [self.elementPosition isEqualToString:viewIdentify.elementPosition];
        } else {
            return [self.clickElementPosition isEqualToString:viewIdentify.elementPosition];
        }
    }
    //属性元素为列表，事件元素非列表，直接匹配位置即可
    return [self.elementPosition isEqualToString:viewIdentify.elementPosition];
}

/// h5 属性配置，匹配元素
- (BOOL)isEqualToWebViewIdentify:(SAViewIdentifier *)object {
    if (!self.isH5) {
        return NO;
    }

    BOOL sameElementPath = [self.webViewElementPath isEqualToString:object.elementPath];
    BOOL sameScreenName = [self.screenName isEqualToString:object.screenName];
    return sameElementPath && sameScreenName;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.regular forKey:@"regular"];
    [coder encodeBool:self.limitPosition forKey:@"limitPosition"];
    [coder encodeInteger:self.type forKey:@"type"];
    [coder encodeBool:self.isH5 forKey:@"h5"];
    [coder encodeObject:self.webViewElementPath forKey:@"webViewElementPath"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.name = [coder decodeObjectForKey:@"name"];
        self.regular = [coder decodeObjectForKey:@"regular"];
        self.limitPosition = [coder decodeBoolForKey:@"limitPosition"];
        self.type = [coder decodeIntegerForKey:@"type"];
        self.h5 = [coder decodeBoolForKey:@"h5"];
        self.webViewElementPath = [coder decodeObjectForKey:@"webViewElementPath"];
    }
    return self;
}

@end

@implementation SAVisualPropertiesConfig

- (instancetype)initWithDictionary:(NSDictionary *)eventsDic {
    self = [super init];
    if (self) {
        NSString *eventTypeString = dictionaryValueForKey(eventsDic, @"event_type");
        if ([eventTypeString isEqualToString:@"appclick"]) {
            _eventType = SensorsAnalyticsEventTypeAppClick;
        } else {
            _eventType = SensorsAnalyticsEventTypeNone;
        }

        _eventName = dictionaryValueForKey(eventsDic, @"event_name");
        NSDictionary *eventDic = dictionaryValueForKey(eventsDic, @"event");
        _event = [[SAVisualPropertiesEventConfig alloc] initWithDictionary:eventDic];

        NSArray<NSDictionary *> *propertiesArray = dictionaryValueForKey(eventsDic, @"properties");
        if (propertiesArray) {

            NSMutableArray<SAVisualPropertiesPropertyConfig *> *properties = [NSMutableArray array];
            NSMutableArray <NSDictionary *>*webProperties = [NSMutableArray array];
            for (NSDictionary *dic in propertiesArray) {
                SAVisualPropertiesPropertyConfig *config = [[SAVisualPropertiesPropertyConfig alloc] initWithDictionary:dic];
                // h5 配置不必解析，单独保存原始 json，直接发送给 js 即可
                if (config.isH5) {
                    [webProperties addObject:dic];
                } else {
                    // 保存是否限定位置
                    config.limitPosition = _event.limitPosition;
                    [properties addObject:config];
                }
            }
            _properties = properties.count > 0 ? [properties copy]: nil;;
            _webProperties = webProperties.count > 0 ? [webProperties copy]: nil;
        }
    }
    return self;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.eventType forKey:@"eventType"];
    [coder encodeObject:self.event forKey:@"event"];
    [coder encodeObject:self.properties forKey:@"properties"];
    [coder encodeObject:self.eventName forKey:@"eventName"];
    [coder encodeObject:self.webProperties forKey:@"webProperties"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.eventType = [coder decodeIntegerForKey:@"eventType"];
        self.event = [coder decodeObjectForKey:@"event"];
        self.properties = [coder decodeObjectForKey:@"properties"];
        self.eventName = [coder decodeObjectForKey:@"eventName"];
        self.webProperties = [coder decodeObjectForKey:@"webProperties"];
    }
    return self;
}

@end

@implementation SAVisualPropertiesResponse

- (instancetype)initWithDictionary:(NSDictionary *)responseDic {
    self = [super init];
    if (self) {
        _version = dictionaryValueForKey(responseDic, @"version");
        _os = dictionaryValueForKey(responseDic, @"os");
        _project = dictionaryValueForKey(responseDic, @"project");
        _appId = dictionaryValueForKey(responseDic, @"app_id");
        _originalResponse = responseDic;

        NSArray <NSDictionary *> *events = dictionaryValueForKey(responseDic, @"events");
        if (events.count > 0) {
            NSMutableArray *eventsArray = [NSMutableArray array];
            for (NSDictionary *eventDic in events) {
                SAVisualPropertiesConfig *event = [[SAVisualPropertiesConfig alloc] initWithDictionary:eventDic];

                // H5 事件配置，不必解析
                if (!event.event.isH5) {
                    [eventsArray addObject:event];
                }
            }
            _events = [eventsArray copy];
        }
    }
    return self;
}


#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.version forKey:@"version"];
    [coder encodeObject:self.os forKey:@"os"];
    [coder encodeObject:self.project forKey:@"project"];
    [coder encodeObject:self.appId forKey:@"appId"];
    [coder encodeObject:self.events forKey:@"events"];
    [coder encodeObject:self.originalResponse forKey:@"originalResponse"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.version = [coder decodeObjectForKey:@"version"];
        self.os = [coder decodeObjectForKey:@"os"];
        self.project = [coder decodeObjectForKey:@"project"];
        self.appId = [coder decodeObjectForKey:@"appId"];
        self.events = [coder decodeObjectForKey:@"events"];
        self.originalResponse = [coder decodeObjectForKey:@"originalResponse"];
    }
    return self;
}

@end
