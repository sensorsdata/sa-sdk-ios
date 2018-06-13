//
//  AutoTrackViewController.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/4/27.
//  Copyright © 2017年 SensorsData. All rights reserved.
//

#import "AutoTrackViewController.h"
#import "AutoTrackUtils.h"
@interface AutoTrackViewController ()

@end

@implementation AutoTrackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _myLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *labelTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelTouchUpInside:)];
    
    [_myLabel addGestureRecognizer:labelTapGestureRecognizer];
    
    UITapGestureRecognizer *imageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewTouchUpInside:)];
    _imageView.userInteractionEnabled = YES;
    [_imageView addGestureRecognizer:imageViewTapGestureRecognizer];
    
    [_myUISwitch addTarget:self action:@selector(picSwitchClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _myButton1.sensorsAnalyticsDelegate = self;
    [_myButton1 setAttributedTitle:[[NSAttributedString alloc]initWithString:@"button1" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13],NSForegroundColorAttributeName:[UIColor redColor]}] forState:UIControlStateNormal];
     [_myLabel setAttributedText:[[NSAttributedString alloc]initWithString:@"label1" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13],NSForegroundColorAttributeName:[UIColor redColor]}]];
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
@end
