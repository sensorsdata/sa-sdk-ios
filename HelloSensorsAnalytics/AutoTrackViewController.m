//
//  AutoTrackViewController.m
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

#import "AutoTrackViewController.h"
#import "AutoTrackUtils.h"
@interface AutoTrackViewController ()
{
    __strong UIGestureRecognizer *_labelTapGestureRecognizer;
}
@end

@implementation AutoTrackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _myLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *labelTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelTouchUpInside:)];
    
    [_myLabel addGestureRecognizer:labelTapGestureRecognizer];
    _labelTapGestureRecognizer = labelTapGestureRecognizer;
    UITapGestureRecognizer *imageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewTouchUpInside:)];
    _imageView.userInteractionEnabled = YES;
    [_imageView addGestureRecognizer:imageViewTapGestureRecognizer];
    
    [_myUISwitch addTarget:self action:@selector(picSwitchClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _myButton1.sensorsAnalyticsDelegate = self;
    [_myButton1 setAttributedTitle:[[NSAttributedString alloc]initWithString:@"button1" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13],NSForegroundColorAttributeName:[UIColor redColor]}] forState:UIControlStateNormal];
     [_myLabel setAttributedText:[[NSAttributedString alloc]initWithString:@"label1" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13],NSForegroundColorAttributeName:[UIColor redColor]}]];
    UIStepper *stepper = [[UIStepper alloc]initWithFrame:CGRectMake(0, 600, 200, 40)];
    [stepper addTarget:self action:@selector(stepperOnClick:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:stepper];
    
    UISlider *slider = [[UISlider alloc]initWithFrame:CGRectMake(220, 600, 100, 40)];
    [slider addTarget:self action:@selector(stepperOnClick:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:slider];

    [_segmentedControl insertSegmentWithTitle:@"3" atIndex:2 animated:YES];

}
-(void)stepperOnClick:(UIStepper*)sender {
    NSLog(@"step on:%f",sender.value);
}
-(void)picSwitchClick:(UISwitch *)sender {
}

-(void) labelTouchUpInside:(UITapGestureRecognizer *)recognizer{
    UILabel *label=(UILabel*)recognizer.view;
    NSLog(@"%@被点击了",label.text);

}

-(void) imageViewTouchUpInside:(UITapGestureRecognizer *)recognizer{
    NSLog(@"UIImageView被点击了");

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onButton1Click:(id)sender {
  NSString *content=  [AutoTrackUtils contentFromView:self.view ];
    NSLog(@"%@",content);

}
- (IBAction)segmentOnClick:(id)sender {

}

-(void)dealloc {
    _labelTapGestureRecognizer = nil;
}
@end
