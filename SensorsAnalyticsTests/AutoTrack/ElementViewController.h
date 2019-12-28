//
//  ElementViewController.h
//  TestSensors
//
//  Created by MC on 2019/5/6.
//  Copyright © 2019-2020 Sensors Data Co., Ltd. All rights reserved.
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
