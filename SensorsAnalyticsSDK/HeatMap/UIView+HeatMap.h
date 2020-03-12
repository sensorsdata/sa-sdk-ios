//  UIView+HeatMap.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/20/16
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface UIView (HeatMap)

- (UIImage *)sa_snapshotImage;
- (UIImage *)sa_snapshotForBlur;

- (NSString *)jjf_varA;
- (NSString *)jjf_varB;
- (NSString *)jjf_varC;
- (NSArray *)jjf_varSetD;
- (NSString *)jjf_varE;

@end



@interface UITableViewCell (HeatMap)
- (NSString *)sa_indexPath;
@end

@interface UICollectionViewCell (HeatMap)
- (NSString *)sa_indexPath;
@end


@interface UITableViewHeaderFooterView (HeatMap)
- (NSString *)sa_section;
@end

