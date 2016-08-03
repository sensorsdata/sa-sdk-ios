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

- (void)testTrack {
    [[SensorsAnalyticsSDK sharedInstance] track:@"testTrack" withProperties:@{@"test": @"test"}];
}

- (void)testTrackSignup {
    [[SensorsAnalyticsSDK sharedInstance] trackSignUp:@"new id"];
}

- (void)testTrackInstallation {
    [[SensorsAnalyticsSDK sharedInstance] trackInstallation:@"AppInstall"];
}

- (void)testProfileSet {
//    [[SensorsAnalyticsSDK sharedInstance].people set:@"name" to:@"caojiang"];
    [[[SensorsAnalyticsSDK sharedInstance] people] setAppPushContext:SensorsAnalyticsAppPushJiguang withRegisterId:@"123456"];
}

- (void)testProfileAppend {
    [[SensorsAnalyticsSDK sharedInstance].people append:@"array" by:[NSSet setWithObjects:@"123", nil]];
}

- (void)testProfileIncrement {
    [[SensorsAnalyticsSDK sharedInstance].people increment:@"age" by:@1];
}

- (void)testProfileUnset {
    [[SensorsAnalyticsSDK sharedInstance].people unset:@"age"];
}

- (void)testProfileDelete {
    [[SensorsAnalyticsSDK sharedInstance].people deleteUser];
}

- (void)testFlush {
    [[SensorsAnalyticsSDK sharedInstance] flush];
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
            NSLog(@"测试track_installation");
            [self testTrackInstallation];
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
        case 9l:
            NSLog(@"进入无埋点测试页面");
            [self testCodeless];
            break;
        default:
            break;
    }
}

@end
