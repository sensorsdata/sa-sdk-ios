//
//  AutoTrackUtils.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/6/29.
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

@interface AutoTrackUtils : NSObject

+ (void)trackAppClickWithUITableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

+ (void)trackAppClickWithUICollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

+ (NSString *)contentFromView:(UIView *)rootView;

//+ (void)sa_addViewPathProperties:(NSMutableDictionary *)properties withObject:(UIView *)view withViewController:(UIViewController *)viewController;

+ (void)sa_addViewPathProperties:(NSMutableDictionary *)properties object:(UIView *)view viewController:(UIViewController *)viewController;

+ (void)trackAppClickWithUITabBar:(UITabBar *)tabbar didSelectItem:(UITabBarItem *)item;

+ (void)trackAppClickWithUIGestureRecognizer:(UIGestureRecognizer *)gesture;
+ (NSString *)titleFromViewController:(UIViewController *)viewController;

@end
