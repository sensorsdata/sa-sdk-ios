//
//  TestViewController.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/9/14.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import "TestViewController.h"
#import "AutoTrackUtils.h"
@interface TestViewController ()

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (IBAction)onButtonClick:(id)sender {
    NSLog(@"****:onButtonClick");
    NSString *content = [AutoTrackUtils contentFromView:self.view];
    NSLog(@"%@",content);
}

- (IBAction)onButtonClick2:(id)sender {
    NSLog(@"****:onButtonClick2");
}
@end
