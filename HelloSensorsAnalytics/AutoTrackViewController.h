//
//  AutoTrackViewController.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/4/27.
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
#import "SensorsAnalyticsSDK.h"

@interface AutoTrackViewController : UIViewController<SAUIViewAutoTrackDelegate>
- (IBAction)onButton1Click:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *myButton1;
@property (weak, nonatomic) IBOutlet UILabel *myLabel;
@property (weak, nonatomic) IBOutlet UISwitch *myUISwitch;
- (IBAction)segmentOnClick:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@end
