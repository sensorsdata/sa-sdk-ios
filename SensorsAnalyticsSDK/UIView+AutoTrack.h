//
//  UIView+sa_autoTrack.h
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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol SAUIViewAutoTrack
@optional
- (NSString *)sa_elementContent;
@end;

@interface UIView (AutoTrack) <SAUIViewAutoTrack>
- (NSString *)sa_elementContent;
@end

@interface UIButton (AutoTrack) <SAUIViewAutoTrack>
- (NSString *)sa_elementContent;
@end

@interface UILabel (AutoTrack) <SAUIViewAutoTrack>
- (NSString *)sa_elementContent;
@end

@interface UITextView (AutoTrack) <SAUIViewAutoTrack>
- (NSString *)sa_elementContent;
@end
