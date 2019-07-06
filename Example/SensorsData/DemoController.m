//
//  DemoController.m
//  SensorsAnalyticsSDK
//
//  Created by ZouYuhan on 1/19/16.
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

#import "TestTableViewController.h"
#import "TestCollectionViewController.h"
#import <Foundation/Foundation.h>

#import "zlib.h"

#import "DemoController.h"

@implementation DemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.sensorsAnalyticsDelegate = self;
}

- (NSDictionary *)getTrackProperties {
    return @{@"shuxing" : @"Gaga"};
}

- (NSString *)getScreenUrl {
    return @"WoShiYiGeURL";
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
}

- (void)testTrack {
    [[SensorsAnalyticsSDK sharedInstance] track:@"testTrack" withProperties:@{@"testName":@"testTrack 测试"}];
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

- (NSDictionary *)sensorsAnalytics_tableView:(UITableView *)tableView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath {
    return @{@"sensorsDelegatePath":[NSString stringWithFormat:@"tableView:%ld-%ld",(long)indexPath.section,(long)indexPath.row]};
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    switch (row) {
        case 0:{
            NSLog(@"测试track");
            [self testTrack];
            TestTableViewController *vc =  [[TestTableViewController alloc] init];
            //TestCollectionViewController *collectionVC = [[TestCollectionViewController alloc]init];
            [self.navigationController pushViewController:vc  animated:YES];
        }
            break;
        case 1l: {
            NSLog(@"测试track_signup");
            [self testTrackSignup];
            TestCollectionViewController_A *collectionVC = [[TestCollectionViewController_A alloc] init];
            [self.navigationController pushViewController:collectionVC animated:YES];
        }
            break;
        case 2l:{
            NSLog(@"测试track_installation");
            [self testTrackInstallation];
            TestCollectionViewController_B *vc =  [[TestCollectionViewController_B alloc] init];
            //TestCollectionViewController *collectionVC = [[TestCollectionViewController alloc]init];
            [self.navigationController pushViewController:vc  animated:YES];
            break;
        }
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
