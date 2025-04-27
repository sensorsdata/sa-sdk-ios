//
//  ViewController.m
//  example-macOS
//
//  Created by 陈玉国 on 2025/3/5.
//

#import "ViewController.h"
#import "WebViewController.h"
#import <SensorsAnalyticsSDK/SensorsAnalyticsSDK.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)testTrack:(id)sender {
    [[SensorsAnalyticsSDK sharedInstance] track:@"HelloWorld"];
}

- (IBAction)testH5:(id)sender {
    WebViewController *vc = [[WebViewController alloc] init];
    [self presentViewControllerAsModalWindow:vc];
}

@end
