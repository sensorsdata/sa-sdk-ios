//
// SAWebElementView.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/2/20.
// Copyright © 2020 SensorsData. All rights reserved.
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

#import "SAWebElementView.h"

@interface SAWebElementView()
@end

@implementation SAWebElementView

- (instancetype)initWithWebView:(WKWebView *)webView webElementInfo:(NSDictionary *)elementInfo {
    self = [super init];
    if (self) {
        UIScrollView *scrollView = webView.scrollView;
        /// webView 缩放系数
        CGFloat zoomScale = scrollView.zoomScale;
        // 位置偏移量
        CGPoint contentOffset = scrollView.contentOffset;

        // NSInteger scale = [pageData[@"scale"] integerValue];
        CGFloat left = [elementInfo[@"left"] floatValue] * zoomScale;
        CGFloat top = [elementInfo[@"top"] floatValue] * zoomScale;
        CGFloat width = [elementInfo[@"width"] floatValue] * zoomScale;
        CGFloat height = [elementInfo[@"height"] floatValue] * zoomScale;
        CGFloat scrollX = [elementInfo[@"scrollX"] floatValue] * zoomScale;
        CGFloat scrollY = [elementInfo[@"scrollY"] floatValue] * zoomScale;
        BOOL visibility = [elementInfo[@"visibility"] boolValue];
        if (height <= 0 || !visibility) {
            return nil;
        }

        CGRect webViewRect = [webView convertRect:webView.bounds toView:nil];
        CGFloat realX = left + webViewRect.origin.x - contentOffset.x + scrollX;
        CGFloat realY = top + webViewRect.origin.y - contentOffset.y + scrollY;

        // H5 元素的显示位置
        CGRect touchViewRect = CGRectMake(realX, realY, width, height);
        // 计算 webView 和 H5 元素的交叉区域
        CGRect validFrame = CGRectIntersection(webViewRect, touchViewRect);
        if (CGRectIsNull(validFrame) || CGSizeEqualToSize(validFrame.size, CGSizeZero)) {
            return nil;
        }
        [self setFrame:validFrame];

        self.userInteractionEnabled = YES;

        NSArray <NSString *> *subelements = elementInfo[@"subelements"];
        _jsSubElementIds = subelements;
        _elementContent = elementInfo[@"$element_content"];
        _elementSelector = elementInfo[@"$element_selector"];
        _visibility = visibility;
        _url = elementInfo[@"$url"];
        _tagName = elementInfo[@"tagName"];
        _title = elementInfo[@"$title"];
        _isFromH5 = YES;
        _jsElementId = elementInfo[@"id"];
        _enableAppClick = [elementInfo[@"enable_click"] boolValue];
        _isListView = [elementInfo[@"is_list_view"] boolValue];
        _elementPath = elementInfo[@"$element_path"];

        NSNumber *position = elementInfo[@"$element_position"];
        if ([position isKindOfClass:NSNumber.class]) {
            _elementPosition = [position stringValue];
        } else {
            _elementPosition = nil;
        }

        _level = [elementInfo[@"level"] integerValue];
        _listSelector = elementInfo[@"list_selector"];
        _webLibVersion = elementInfo[@"lib_version"];
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
    if (self.elementPosition) {
        [description appendFormat:@", elementPosition:%@", self.elementPosition];
    }
    if (self.listSelector) {
        [description appendFormat:@", listSelector:%@", self.listSelector];
    }
    if (self.url) {
        [description appendFormat:@", url:%@", self.url];
    }
    if (self.jsSubviews) {
        [description appendFormat:@", jsSubviews:%@", self.jsSubviews];
    }

    return [description copy];
}
@end
