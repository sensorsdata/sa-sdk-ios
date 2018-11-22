//
//  UIView+sa_autoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/6/11.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "UIView+AutoTrack.h"

@implementation UIView (AutoTrack)
-(NSString *)sa_elementContent {
    return nil;
}
@end

@implementation UIButton (AutoTrack)
-(NSString *)sa_elementContent {
    NSString *sa_elementContent = self.currentAttributedTitle.string;
    if (sa_elementContent != nil && sa_elementContent.length > 0) {
        return sa_elementContent;
    }
    return self.currentTitle;
}
@end

@implementation UILabel (AutoTrack)
-(NSString *)sa_elementContent {
    NSString *attributedText = self.attributedText.string;
    if (attributedText != nil && attributedText.length > 0) {
        return attributedText;
    }
    return self.text;
}
@end

@implementation UITextView (AutoTrack)
-(NSString *)sa_elementContent {
    NSString *attributedText = self.attributedText.string;
    if (attributedText != nil && attributedText.length > 0) {
        return attributedText;
    }
    return  self.text;
}
@end
