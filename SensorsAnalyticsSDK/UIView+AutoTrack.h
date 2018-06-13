//
//  UIView+sa_autoTrack.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/6/11.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol SAUIViewAutoTrack
@optional
-(NSString *)sa_elementContent;
@end;

@interface UIView (AutoTrack)<SAUIViewAutoTrack>
-(NSString *)sa_elementContent;
@end

@interface UIButton (AutoTrack)<SAUIViewAutoTrack>
-(NSString *)sa_elementContent;
@end

@interface UILabel (AutoTrack)<SAUIViewAutoTrack>
-(NSString *)sa_elementContent;
@end

@interface UITextView (AutoTrack)<SAUIViewAutoTrack>
-(NSString *)sa_elementContent;
@end
