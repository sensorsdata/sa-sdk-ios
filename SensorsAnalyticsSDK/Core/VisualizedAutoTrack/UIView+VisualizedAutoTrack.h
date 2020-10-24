//
// UIView+VisualizedAutoTrack.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/6.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "SAAutoTrackProperty.h"
#import "SAJSTouchEventView.h"
#import "SAVisualizedViewPathProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (VisualizedAutoTrack)<SAVisualizedViewPathProperty, SAVisualizedExtensionProperty>

@end

@interface UIScrollView (VisualizedAutoTrack)<SAVisualizedExtensionProperty>
@end

@interface UISwitch (VisualizedAutoTrack)<SAVisualizedViewPathProperty>
@end

@interface UIStepper (VisualizedAutoTrack)<SAVisualizedViewPathProperty>
@end

@interface UISlider (VisualizedAutoTrack)<SAVisualizedViewPathProperty>
@end

@interface UIPageControl (VisualizedAutoTrack)<SAVisualizedViewPathProperty>
@end

@interface WKWebView (VisualizedAutoTrack)<SAVisualizedViewPathProperty>

@end

@interface UIWindow (VisualizedAutoTrack)<SAVisualizedViewPathProperty>
@end

@interface UITableView (VisualizedAutoTrack)<SAVisualizedViewPathProperty>
@end

@interface UICollectionView (VisualizedAutoTrack)<SAVisualizedViewPathProperty>
@end

@interface UITableViewCell (VisualizedAutoTrack)<SAAutoTrackViewProperty>
@end

@interface UICollectionViewCell (VisualizedAutoTrack)<SAAutoTrackViewProperty>
@end

@interface UITableViewHeaderFooterView (VisualizedAutoTrack)
@end

@interface SAJSTouchEventView (VisualizedAutoTrack)<SAVisualizedViewPathProperty>
@end

@interface UIViewController (VisualizedAutoTrack)<SAVisualizedViewPathProperty>
@end

NS_ASSUME_NONNULL_END
