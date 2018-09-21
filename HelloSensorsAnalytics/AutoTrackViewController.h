//
//  AutoTrackViewController.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/4/27.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
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
