//
//  UIView+sa_autoTrack.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/6/11.
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

#import <UIKit/UIKit.h>
#import "SAAutoTrackProperty.h"

#pragma mark - UIView

@interface UIView (AutoTrack) <SAAutoTrackViewProperty, SAAutoTrackViewPathProperty>
@end

@interface UILabel (AutoTrack) <SAAutoTrackViewProperty>
@end

@interface UIImageView (AutoTrack) <SAAutoTrackViewProperty>
@end

@interface UITextView (AutoTrack) <SAAutoTrackViewProperty>
@end

@interface UITabBar (AutoTrack) <SAAutoTrackViewProperty>
@end

@interface UISearchBar (AutoTrack) <SAAutoTrackViewProperty>
@end

@interface UITableViewHeaderFooterView (AutoTrack) <SAAutoTrackViewPathProperty>
@end

#pragma mark - UIControl

@interface UIButton (AutoTrack) <SAAutoTrackViewProperty>
@end

@interface UISwitch (AutoTrack) <SAAutoTrackViewProperty>
@end

@interface UIStepper (AutoTrack) <SAAutoTrackViewProperty>
@end

@interface UISegmentedControl (AutoTrack) <SAAutoTrackViewProperty>
@end

#pragma mark - UITabBarItem
@interface UITabBarItem (AutoTrack) <SAAutoTrackViewProperty>
@end

#pragma mark - Cell
@interface UITableViewCell (AutoTrack) <SAAutoTrackCellProperty>
@end

@interface UICollectionViewCell (AutoTrack) <SAAutoTrackCellProperty>
@end
