//
//  UIView+sa_autoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/6/11.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "UIView+AutoTrack.h"

@implementation UIView (AutoTrack)
- (NSString *)sa_elementContent {
    return nil;
}
@end

@implementation UIButton (AutoTrack)
- (NSString *)sa_elementContent {
    NSString *sa_elementContent = self.currentAttributedTitle.string;
    if (sa_elementContent != nil && sa_elementContent.length > 0) {
        return sa_elementContent;
    }
    return self.currentTitle;
}
@end

@implementation UILabel (AutoTrack)
- (NSString *)sa_elementContent {
    NSString *attributedText = self.attributedText.string;
    if (attributedText != nil && attributedText.length > 0) {
        return attributedText;
    }
    return self.text;
}
@end

@implementation UITextView (AutoTrack)
- (NSString *)sa_elementContent {
    NSString *attributedText = self.attributedText.string;
    if (attributedText != nil && attributedText.length > 0) {
        return attributedText;
    }
    return  self.text;
}
@end
