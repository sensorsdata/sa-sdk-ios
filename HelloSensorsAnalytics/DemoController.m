//
//  DemoController.m
//  SensorsAnalyticsSDK
//
//  Created by ZouYuhan on 1/19/16.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//
#import "TestTableViewController.h"
#import "TestCollectionViewController.h"
#import <Foundation/Foundation.h>

#import "zlib.h"

#import "DemoController.h"

@implementation DemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.sensorsAnalyticsDelegate = self;
}

- (NSDictionary *)getTrackProperties {
    return @{@"shuxing" : @"Gaga"};
}

- (NSString *)getScreenUrl {
    return @"WoShiYiGeURL";
}

- (NSDictionary*)sa_tableView:(UITableView *)tableView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath {
    return @{@"test": @"test"};
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
}

- (void)testTrack {
    [[SensorsAnalyticsSDK sharedInstance] track:@"testTrack" withProperties:nil];
}

- (void)testTrackSignup {
    [[SensorsAnalyticsSDK sharedInstance] login:@"newId"];
}

- (void)testTrackInstallation {
    [[SensorsAnalyticsSDK sharedInstance] trackInstallation:@"AppInstall" withProperties:nil];
}

- (void)testProfileSet {
    [[SensorsAnalyticsSDK sharedInstance] set:@"name" to:@"caojiang"];
}

- (void)testProfileAppend {
    [[SensorsAnalyticsSDK sharedInstance] append:@"array" by:[NSSet setWithObjects:@"123", nil]];
}

- (void)testProfileIncrement {
    [[SensorsAnalyticsSDK sharedInstance] increment:@"age" by:@1];
}

- (void)testProfileUnset {
    [[SensorsAnalyticsSDK sharedInstance] unset:@"age"];
}

- (void)testProfileDelete {
    [[SensorsAnalyticsSDK sharedInstance] deleteUser];
}

- (void)testFlush {
    [[SensorsAnalyticsSDK sharedInstance] flush];
}

- (void)testCodeless {
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    switch (row) {
        case 0:{
            NSLog(@"测试track");
            //[self testTrack];
            TestTableViewController *vc =  [[TestTableViewController alloc]init ];
            //TestCollectionViewController *collectionVC = [[TestCollectionViewController alloc]init];
            [self.navigationController pushViewController:vc  animated:YES];
        }
            break;
        case 1l: {
            NSLog(@"测试track_signup");
            [self testTrackSignup];
            TestCollectionViewController *collectionVC = [[TestCollectionViewController alloc] init];
            [self.navigationController pushViewController:collectionVC animated:YES];
        }
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
