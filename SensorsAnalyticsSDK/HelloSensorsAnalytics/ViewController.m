//
//  ViewController.m
//  HelloSensorsAnalytics
//
//  Created by 曹犟 on 15/7/4.
//  Copyright (c) 2015年 SensorsData. All rights reserved.
//

#import "ViewController.h"
#import "SensorsAnalyticsSDK.h"

#import "zlib.h"

@class SensorsAnalyticsSDK;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)testInit {
    [SensorsAnalyticsSDK sharedInstanceWithServerURL:@"http://test03:8100/sa" andFlushInterval:1000];
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
        [sdk.people set:@"name" to:@"caojiang"];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    switch (row) {
        case 0l:
            NSLog(@"测试初始化");
            [self testInit];
            break;
        case 1l:
            NSLog(@"测试track");
            [self testTrack];
            break;
        case 2l:
            NSLog(@"测试track_signup");
            [self testTrackSignup];
            break;
        case 3l:
            NSLog(@"测试profile_set");
            [self testProfileSet];
            break;
        case 4l:
            NSLog(@"测试profile_append");
            [self testProfileAppend];
            break;
        case 5l:
            NSLog(@"测试profile_increment");
            [self testProfileIncrement];
            break;
        case 6l:
            NSLog(@"测试profile_unset");
            [self testProfileUnset];
            break;
        case 7l:
            NSLog(@"测试profile_delete");
            [self testProfileDelete];
            break;
        case 8l:
            NSLog(@"测试flush");
            [self testFlush];
            break;
        default:
            break;
    }
}

@end
