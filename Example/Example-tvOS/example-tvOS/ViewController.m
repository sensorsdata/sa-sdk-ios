//
//  ViewController.m
//  example-tvOS
//
//  Created by 陈玉国 on 2025/3/5.
//

#import "ViewController.h"
#import <SensorsAnalyticsSDK/SensorsAnalyticsSDK.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)testTrack:(id)sender {
    [[SensorsAnalyticsSDK sharedInstance] track:@"HelloWorld"];
}
- (IBAction)flushAction:(UIButton *)sender {
    [SensorsAnalyticsSDK.sharedInstance flush];
}

@end
