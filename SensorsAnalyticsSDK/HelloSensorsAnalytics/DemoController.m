//
//  DemoController.m
//  SensorsAnalyticsSDK
//
//  Created by ZouYuhan on 1/19/16.
//  Copyright © 2016 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "zlib.h"

#import "SensorsAnalyticsSDK.h"

#import "DemoController.h"

@implementation DemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self testInit];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)testInit {
    [SensorsAnalyticsSDK sharedInstanceWithServerURL:@"http://sa_host:8006/sa?token=e6a62d9f88674650"
                                     andConfigureURL:@"http://sa_host:8007/api/vtrack/config/iOS.conf"
                                  andVTrackServerURL:@"ws://sa_host:8007/ws"
                                        andDebugMode:SensorsAnalyticsDebugOnly];
}

- (void)testTrack {
    SensorsAnalyticsSDK *sdk = [SensorsAnalyticsSDK sharedInstance];
    if (sdk != nil) {
        [sdk track:@"testTrack" withProperties:@{@"test": @"test"}];
    }
}

- (void)testTrackSignup {
    SensorsAnalyticsSDK *sdk = [SensorsAnalyticsSDK sharedInstance];
    if (sdk != nil) {
        [sdk signUp:@"new id"];
    }
}

- (void)testProfileSet {
    SensorsAnalyticsSDK *sdk = [SensorsAnalyticsSDK sharedInstance];
    if (sdk != nil) {
        [sdk.people set:@"name" withValue:@"caojiang"];
    }
    
}

- (void)testProfileAppend {
    SensorsAnalyticsSDK *sdk = [SensorsAnalyticsSDK sharedInstance];
    if (sdk != nil) {
        [sdk.people append:@"array" by:[NSSet setWithObjects:@"123", nil]];
    }
    
}

- (void)testProfileIncrement {
    SensorsAnalyticsSDK *sdk = [SensorsAnalyticsSDK sharedInstance];
    if (sdk != nil) {
        [sdk.people increment:@"age" by:@1];
    }
    
}

- (void)testProfileUnset {
    SensorsAnalyticsSDK *sdk = [SensorsAnalyticsSDK sharedInstance];
    if (sdk != nil) {
        [sdk.people increment:@"age" by:@1];
    }
    
}

- (void)testProfileDelete {
    SensorsAnalyticsSDK *sdk = [SensorsAnalyticsSDK sharedInstance];
    if (sdk != nil) {
        [sdk.people deleteUser];
    }
    
}

- (void)testFlush {
    SensorsAnalyticsSDK *sdk = [SensorsAnalyticsSDK sharedInstance];
    if (sdk != nil) {
        [sdk flush];
    }
}

- (void)testCodeless {
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    switch (row) {
        case 0l:
        NSLog(@"测试track");
        [self testTrack];
        break;
        case 1l:
        NSLog(@"测试track_signup");
        [self testTrackSignup];
        break;
        case 2l:
        NSLog(@"测试profile_set");
        [self testProfileSet];
        break;
        case 3l:
        NSLog(@"测试profile_append");
        [self testProfileAppend];
        break;
        case 4l:
        NSLog(@"测试profile_increment");
        [self testProfileIncrement];
        break;
        case 5l:
        NSLog(@"测试profile_unset");
        [self testProfileUnset];
        break;
        case 6l:
        NSLog(@"测试profile_delete");
        [self testProfileDelete];
        break;
        case 7l:
        NSLog(@"测试flush");
        [self testFlush];
        break;
        case 8l:
        NSLog(@"进入无埋点测试页面");
        [self testCodeless];
        break;
        default:
        break;
    }
}

@end
