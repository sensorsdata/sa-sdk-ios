//
// ElementViewController.h
// TestSensors
//
// Created by MC on 2019/5/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomButton : UIButton

@end

@interface ElementViewController : UIViewController

@property (nonatomic, strong) UIButton *firstButton;
@property (nonatomic, strong) CustomButton *secondButton;

@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIStepper *stepper;
@property (nonatomic, strong) UISwitch *uiswitch;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UITableView *tableView;

@end

NS_ASSUME_NONNULL_END
