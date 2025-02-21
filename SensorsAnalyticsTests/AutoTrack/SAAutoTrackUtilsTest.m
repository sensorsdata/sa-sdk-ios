//
// SAAutoTrackUtilsTest.m
// SensorsAnalyticsTests
//
// Created by MC on 2019/5/5.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
    

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "SensorsAnalyticsSDK.h"
#import "SAAutoTrackUtils.h"
#import "SAUIProperties.h"
#import "ElementViewController.h"
#import "UIView+SAAutoTrack.h"
#import "UIViewController+SAAutoTrack.h"

@interface SAAutoTrackUtilsTest : XCTestCase
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) ElementViewController *viewController;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UITabBarController *tabBarController;
@end

@implementation SAAutoTrackUtilsTest

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

- (void)testFindNextViewControllerByResponder {
    UIViewController *vc = [SAUIProperties
                            findNextViewControllerByResponder:self.viewController.label];
    XCTAssertEqualObjects(self.viewController, vc);
}

- (void)testAutoTrackPropertiesWithButton {
    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.firstButton viewController:self.viewController];

    XCTAssertTrue([dic[@"$title"] isEqualToString:@"Element"]);
    XCTAssertTrue([dic[@"$screen_name"] isEqualToString:@"ElementViewController"]);

    XCTAssertTrue([dic[@"$element_id"] isEqualToString:@"FirstButtonViewId"]);
    XCTAssertTrue([dic[@"$element_type"] isEqualToString:@"UIButton"]);
    XCTAssertTrue([dic[@"$element_content"] isEqualToString:@"FirstButton"]);
}

- (void)testAutoTrackPropertiesWithCustomButton {
    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.secondButton viewController:self.viewController];

    XCTAssertTrue([dic[@"$title"] isEqualToString:@"Element"]);
    XCTAssertTrue([dic[@"$screen_name"] isEqualToString:@"ElementViewController"]);

    XCTAssertNil(dic[@"$element_id"]);
    XCTAssertNil(dic[@"$element_position"]);
    XCTAssertTrue([dic[@"$element_type"] isEqualToString:@"CustomButton"]);
    XCTAssertTrue([dic[@"$element_content"] isEqualToString:@"SecondButton"]);
}

- (void)testAutoTrackPropertiesWithSlider {
    self.viewController.slider.value = 0.5555;
    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.slider viewController:self.viewController];

    XCTAssertTrue([dic[@"$title"] isEqualToString:@"Element"]);
    XCTAssertTrue([dic[@"$screen_name"] isEqualToString:@"ElementViewController"]);

    XCTAssertNil(dic[@"$element_id"]);
    XCTAssertNil(dic[@"$element_position"]);
    XCTAssertTrue([dic[@"$element_type"] isEqualToString:@"UISlider"]);
    XCTAssertTrue([dic[@"$element_content"] doubleValue] == 0.5555);
}

- (void)testAutoTrackPropertiesWithStepper {
    self.viewController.stepper.value = 99;

    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.stepper viewController:self.viewController];

    XCTAssertTrue([dic[@"$title"] isEqualToString:@"Element"]);
    XCTAssertTrue([dic[@"$screen_name"] isEqualToString:@"ElementViewController"]);

    XCTAssertNil(dic[@"$element_id"]);
    XCTAssertNil(dic[@"$element_position"]);
    XCTAssertTrue([dic[@"$element_type"] isEqualToString:@"UIStepper"]);
    XCTAssertTrue([dic[@"$element_content"] doubleValue] == 99);
}

- (void)testAutoTrackPropertiesWithSwitch {
    self.viewController.uiswitch.on = YES;

    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.uiswitch viewController:self.viewController];

    XCTAssertTrue([dic[@"$title"] isEqualToString:@"Element"]);
    XCTAssertTrue([dic[@"$screen_name"] isEqualToString:@"ElementViewController"]);

    XCTAssertNil(dic[@"$element_id"]);
    XCTAssertNil(dic[@"$element_position"]);
    XCTAssertTrue([dic[@"$element_type"] isEqualToString:@"UISwitch"]);
    XCTAssertTrue([dic[@"$element_content"] isEqualToString:@"checked"]);
}

- (void)testAutoTrackPropertiesWithSegmentedControl {
    self.viewController.segmentedControl.selectedSegmentIndex = 1;

    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.segmentedControl viewController:self.viewController];

    XCTAssertTrue([dic[@"$title"] isEqualToString:@"Element"]);
    XCTAssertTrue([dic[@"$screen_name"] isEqualToString:@"ElementViewController"]);

    XCTAssertNil(dic[@"$element_id"]);
    XCTAssertTrue([dic[@"$element_type"] isEqualToString:@"UISegmentedControl"]);
    XCTAssertTrue([dic[@"$element_content"] isEqualToString:@"第二个"]);
    XCTAssertTrue([dic[@"$element_position"] isEqualToString:@"1"]);
}

- (void)testAutoTrackPropertiesWithTapLabel {
    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.label viewController:self.viewController];

    XCTAssertTrue([dic[@"$title"] isEqualToString:@"Element"]);
    XCTAssertTrue([dic[@"$screen_name"] isEqualToString:@"ElementViewController"]);

    XCTAssertNil(dic[@"$element_id"]);
    XCTAssertTrue([dic[@"$element_type"] isEqualToString:@"UILabel"]);
    XCTAssertTrue([dic[@"$element_content"] isEqualToString:@"这是一个可以点击的 Label"]);
    XCTAssertNil(dic[@"$element_position"]);
}

- (void)testAutoTrackPropertiesWithTapImageView {
    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.imageView viewController:self.viewController];

    XCTAssertTrue([dic[@"$title"] isEqualToString:@"Element"]);
    XCTAssertTrue([dic[@"$screen_name"] isEqualToString:@"ElementViewController"]);

    XCTAssertNil(dic[@"$element_id"]);
    XCTAssertTrue([dic[@"$element_type"] isEqualToString:@"UIImageView"]);
    XCTAssertNil(dic[@"$element_content"]);
    XCTAssertNil(dic[@"$element_position"]);
}

- (void)testAutoTrackPropertiesWithTableView {
    // row 太大可能未在屏幕显示，取不到 cell
    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.tableView didSelectedAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];

    XCTAssertTrue([dic[@"$title"] isEqualToString:@"Element"]);
    XCTAssertTrue([dic[@"$screen_name"] isEqualToString:@"ElementViewController"]);

    XCTAssertNil(dic[@"$element_id"]);
    XCTAssertTrue([dic[@"$element_type"] isEqualToString:@"UITableView"]);
    XCTAssertTrue([dic[@"$element_content"] isEqualToString:@"Section: 0, Row: 2"]);
    XCTAssertTrue([dic[@"$element_position"] isEqualToString:@"0:2"]);
}

- (void)testCategoryDelegateProperty {
    UIView *view = [[UIView alloc]init];
    NSObject *delegate = [[NSObject alloc]init];
    view.sensorsAnalyticsDelegate = (NSObject<SAUIViewAutoTrackDelegate>*) delegate;
    delegate = nil;
    XCTAssertNil(view.sensorsAnalyticsDelegate);
}

- (void)testViewTypeIgnoredOfSubClass {
    [[SensorsAnalyticsSDK sharedInstance] ignoreViewType:[UIControl class]];
    BOOL buttonIgnored = [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UIButton class]];
    XCTAssertTrue(buttonIgnored);

    BOOL segmentedControlIgnored = [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UISegmentedControl class]];
    XCTAssertTrue(segmentedControlIgnored);
}

- (void)testViewTypeIgnoredOfCurrentClass {
    [[SensorsAnalyticsSDK sharedInstance] ignoreViewType:[UIControl class]];
    BOOL controlIgnored = [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UIControl class]];
    XCTAssertTrue(controlIgnored);
}

- (void)testViewTypeIgnoredOfSuperClass {
    [[SensorsAnalyticsSDK sharedInstance] ignoreViewType:[UIControl class]];
    BOOL viewIgnored = [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UIView class]];
    XCTAssertFalse(viewIgnored);
}

- (void)testViewTypeIgnoredOfOtherClass {
    [[SensorsAnalyticsSDK sharedInstance] ignoreViewType:[UIControl class]];
    BOOL itemIgnored = [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UIBarButtonItem class]];
    XCTAssertFalse(itemIgnored);
}

- (void)testPerformanceExample {
    [self measureBlock:^{
        [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.firstButton viewController:self.viewController];
        [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.secondButton viewController:self.viewController];
        [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.slider viewController:self.viewController];
        [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.stepper viewController:self.viewController];
        [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.uiswitch viewController:self.viewController];
        [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.segmentedControl viewController:self.viewController];
        [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.label viewController:self.viewController];
        [SAAutoTrackUtils propertiesWithAutoTrackObject:self.viewController.imageView viewController:self.viewController];
    }];
}

@end
