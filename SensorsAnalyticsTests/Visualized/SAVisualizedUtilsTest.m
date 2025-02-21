//
// SAVisualizedUtilsTest.m
// SensorsAnalyticsTests
//
// Created by  储强盛 on 2022/1/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "SensorsAnalyticsSDK.h"
#import "SAVisualizedUtils.h"
#import "SAAutoTrackUtils.h"
#import "ElementViewController.h"
#import "NSObject+SADelegateProxy.h"
#import "SAUIProperties.h"

@interface SAVisualizedUtilsTest : XCTestCase
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) ElementViewController *viewController;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UITabBarController *tabBarController;
@end

@implementation SAVisualizedUtilsTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = [UIColor whiteColor];

    self.viewController = [[ElementViewController alloc] init];

    self.tabBarController = [[UITabBarController alloc] init];

    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    self.navigationController.tabBarItem.title = @"Element";

    UITableViewController *firstViewController = [[UITableViewController alloc] init];
    UINavigationController *firstNavigationController = [[UINavigationController alloc] initWithRootViewController:firstViewController];

    self.tabBarController.viewControllers = @[firstNavigationController, self.navigationController];
    self.window.rootViewController = self.tabBarController;

    [self.viewController view];
    [self.viewController viewWillAppear:NO];
    [self.viewController viewDidAppear:NO];

    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0" launchOptions:nil];
    options.enableVisualizedProperties = YES;
    options.enableHeatMap = YES;
    options.autoTrackEventType = SensorsAnalyticsEventTypeAppStart | SensorsAnalyticsEventTypeAppEnd | SensorsAnalyticsEventTypeAppClick | SensorsAnalyticsEventTypeAppViewScreen;
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.

    [self.tabBarController viewWillDisappear:NO];
    [self.tabBarController viewDidDisappear:NO];

    self.window.rootViewController = nil;
    self.tabBarController = nil;
    self.navigationController = nil;
    self.viewController = nil;

    self.window.hidden = YES;
    self.window = nil;
}


- (void)testAutoTrackPropertiesWithButton {
    NSString *viewPath = [SAVisualizedUtils viewSimilarPathForView:self.viewController.firstButton atViewController:self.viewController];
    NSString *elementPath = @"UIView/UIScrollView[0]/UIButton[0]";
    
    XCTAssertTrue([viewPath isEqualToString:elementPath]);
}

- (void)testAutoTrackPropertiesWithCustomButton {
    NSString *viewPath = [SAVisualizedUtils viewSimilarPathForView:self.viewController.secondButton atViewController:self.viewController];

    NSString *elementPath = @"UIView/UIScrollView[0]/CustomButton[0]";
    XCTAssertTrue([viewPath isEqualToString:elementPath]);
}

- (void)testAutoTrackPropertiesWithSlider {
    self.viewController.slider.value = 0.5555;
    NSString *viewPath = [SAVisualizedUtils viewSimilarPathForView:self.viewController.slider atViewController:self.viewController];

    NSString *elementPath = @"UIView/UIScrollView[0]/UISlider[0]";
    XCTAssertTrue([viewPath isEqualToString:elementPath]);
}

- (void)testAutoTrackPropertiesWithStepper {
    self.viewController.stepper.value = 99;

    NSString *viewPath = [SAVisualizedUtils viewSimilarPathForView:self.viewController.stepper atViewController:self.viewController];

    NSString *elementPath = @"UIView/UIScrollView[0]/UIStepper[0]";
    XCTAssertTrue([viewPath isEqualToString:elementPath]);
}

- (void)testAutoTrackPropertiesWithSwitch {
    self.viewController.uiswitch.on = YES;

    NSString *viewPath = [SAVisualizedUtils viewSimilarPathForView:self.viewController.uiswitch atViewController:self.viewController];

    NSString *elementPath = @"UIView/UIScrollView[0]/UISwitch[0]";
    XCTAssertTrue([viewPath isEqualToString:elementPath]);
}

- (void)testAutoTrackPropertiesWithSegmentedControl {
    self.viewController.segmentedControl.selectedSegmentIndex = 1;
    NSString *viewPath = [SAVisualizedUtils viewSimilarPathForView:self.viewController.segmentedControl atViewController:self.viewController];

    NSString *elementPath = @"UIView/UIScrollView[0]/UISegmentedControl[0]/UISegment[-]";
    XCTAssertTrue([viewPath isEqualToString:elementPath]);
}

- (void)testAutoTrackPropertiesWithTapLabel {
    NSString *viewPath = [SAVisualizedUtils viewSimilarPathForView:self.viewController.label atViewController:self.viewController];

    NSString *elementPath = @"UIView/UIScrollView[0]/UILabel[0]";
    XCTAssertTrue([viewPath isEqualToString:elementPath]);
}

- (void)testAutoTrackPropertiesWithTapImageView {
    NSString *viewPath = [SAVisualizedUtils viewSimilarPathForView:self.viewController.imageView atViewController:self.viewController];

    NSString *elementPath = @"UIView/UIScrollView[0]/UIImageView[0]";
    XCTAssertTrue([viewPath isEqualToString:elementPath]);
}

- (void)testAutoTrackPropertiesWithTableView {
    // row 太大可能未在屏幕显示，取不到 cell
    UITableViewCell *cell = (UITableViewCell *)[SAUIProperties cellWithScrollView:self.viewController.tableView andIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    NSString *viewPath = [SAVisualizedUtils viewSimilarPathForView:cell atViewController:self.viewController];
    
    NSString *elementPath = @"UIView/UITableView[0]/UITableViewCell[0][-]";
    XCTAssertTrue([viewPath isEqualToString:elementPath]);
}

- (void)testPerformanceExample {
    [self measureBlock:^{
        [SAVisualizedUtils viewSimilarPathForView:self.viewController.firstButton atViewController:self.viewController];
        [SAVisualizedUtils viewSimilarPathForView:self.viewController.secondButton atViewController:self.viewController];
        [SAVisualizedUtils viewSimilarPathForView:self.viewController.slider atViewController:self.viewController];

        [SAVisualizedUtils viewSimilarPathForView:self.viewController.stepper atViewController:self.viewController];
        [SAVisualizedUtils viewSimilarPathForView:self.viewController.uiswitch atViewController:self.viewController];
        [SAVisualizedUtils viewSimilarPathForView:self.viewController.segmentedControl atViewController:self.viewController];
        [SAVisualizedUtils viewSimilarPathForView:self.viewController.label atViewController:self.viewController];
        [SAVisualizedUtils viewSimilarPathForView:self.viewController.imageView atViewController:self.viewController];
    }];
}

@end


