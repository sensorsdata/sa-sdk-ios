//
// SAVisualizedElementView.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/27.
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

#import "SAVisualizedElementView.h"

@interface SAVisualizedElementView()

@end

@implementation SAVisualizedElementView

- (instancetype)initWithSuperView:(UIView *)superView elementInfo:(NSDictionary *)elementInfo {
    self = [super init];
    if (self) {
        CGFloat left = [elementInfo[@"left"] floatValue];
        CGFloat top = [elementInfo[@"top"] floatValue];
        CGFloat width = [elementInfo[@"width"] floatValue];
        CGFloat height = [elementInfo[@"height"] floatValue];
        if (height <= 0) {
            return nil;
        }

        CGRect viewRect = [superView convertRect:superView.bounds toView:nil];
        CGFloat realX = left + viewRect.origin.x;
        CGFloat realY = top + viewRect.origin.y;

        // H5 元素的显示位置
        CGRect touchViewRect = CGRectMake(realX, realY, width, height);
        // 计算 webView 和 H5 元素的交叉区域
        CGRect validFrame = CGRectIntersection(viewRect, touchViewRect);
        if (CGRectIsNull(validFrame) || CGSizeEqualToSize(validFrame.size, CGSizeZero)) {
            return nil;
        }
        [self setFrame:validFrame];

        self.userInteractionEnabled = YES;


        NSArray <NSString *> *subelements = elementInfo[@"subelements"];
        _subElementIds = subelements;
        _elementContent = elementInfo[@"$element_content"];
        _title = elementInfo[@"title"];
        _screenName = elementInfo[@"screen_name"];
        _elementId = elementInfo[@"id"];
        _enableAppClick = [elementInfo[@"enable_click"] boolValue];
        _isListView = [elementInfo[@"is_list_view"] boolValue];
        _elementPath = elementInfo[@"$element_path"];

        _elementPosition = elementInfo[@"$element_position"];

        _level = [elementInfo[@"level"] integerValue];

        _platform = @"h5";

    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithString:NSStringFromClass(self.class)];
    if (self.elementContent) {
        [description appendFormat:@", elementContent:%@", self.elementContent];
    }
    if (self.level > 0) {
        [description appendFormat:@", level:%ld", (long)self.level];
    }
    if (self.elementPath) {
        [description appendFormat:@", elementPath:%@", self.elementPath];
    }
    [description appendFormat:@", enableAppClick:%@", @(self.enableAppClick)];

    if (self.elementPosition) {
        [description appendFormat:@", elementPosition:%@", self.elementPosition];
    }
    if (self.screenName) {
        [description appendFormat:@", screenName:%@", self.screenName];
    }
    if (self.subElements) {
        [description appendFormat:@", subElements:%@", self.subElements];
    }
    return [description copy];
}

@end
