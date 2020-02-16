//
//  ElementViewController.m
//  TestSensors
//
//  Created by MC on 2019/5/6.
//  Copyright © 2019-2020 Sensors Data Co., Ltd. All rights reserved.
//

#import "ElementViewController.h"
#import "SensorsAnalyticsSDK.h"


@implementation CustomButton

@end

#pragma mark -
@interface ElementViewController () <UITableViewDataSource, UITableViewDelegate, SAUIViewAutoTrackDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@end

@implementation ElementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Element";

    CGFloat x = 16;
    CGFloat y = 16;
    CGFloat width = self.view.frame.size.width - 2 * x;

    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)/2)];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_scrollView];

    _firstButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _firstButton.frame = CGRectMake(x, y, width, 44);
    _firstButton.sensorsAnalyticsViewID = @"FirstButtonViewId";
    [_firstButton setTitle:@"FirstButton" forState:UIControlStateNormal];
    [_firstButton setTitle:@"SelectedFirstButton" forState:UIControlStateSelected];
    [_firstButton addTarget:self action:@selector(firstAction:) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:_firstButton];

    y = CGRectGetMaxY(_firstButton.frame) + 16;
    _secondButton = [CustomButton buttonWithType:UIButtonTypeSystem];
    _secondButton.frame = CGRectMake(x, y, width, 44);
    [_secondButton setTitle:@"SecondButton" forState:UIControlStateNormal];
    [_secondButton setTitle:@"SelectedSecondButton" forState:UIControlStateSelected];
    [_secondButton addTarget:self action:@selector(secondAction:) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:_secondButton];

    y = CGRectGetMaxY(_secondButton.frame) + 16;
    _stepper = [[UIStepper alloc] initWithFrame:CGRectMake(x, y, width, 40)];
    [_stepper addTarget:self action:@selector(stepperAction:) forControlEvents:UIControlEventValueChanged];
    [_scrollView addSubview:_stepper];

    y = CGRectGetMaxY(_stepper.frame) + 16;
    _slider = [[UISlider alloc] initWithFrame:CGRectMake(x, y, width, 40)];
    [_slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    [_scrollView addSubview:_slider];

    y = CGRectGetMaxY(_slider.frame) + 16;
    _uiswitch = [[UISwitch alloc] init];
    _uiswitch.frame = CGRectMake(x, y, width, 40);
    [_uiswitch addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    [_scrollView addSubview:_uiswitch];

    y = CGRectGetMaxY(_uiswitch.frame) + 16;
    _segmentedControl.frame = CGRectMake(x, y, width, 40);
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"第一个", @"第二个", @"第三个"]];
    [_segmentedControl addTarget:self action:@selector(segmentedAction:) forControlEvents:UIControlEventValueChanged];
    [_scrollView addSubview:_segmentedControl];

    y = CGRectGetMaxY(_segmentedControl.frame) + 16;
    _label = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, 200)];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.text = @"这是一个可以点击的 Label";
    _label.userInteractionEnabled = YES;
    [_scrollView addSubview:_label];

    y = CGRectGetMaxY(_label.frame) + 16;
    _imageView = [[UIImageView alloc] init];
    _imageView.userInteractionEnabled = YES;
    _imageView.frame = CGRectMake(x, y, width, width);
    _imageView.backgroundColor = [UIColor lightGrayColor];
    [_scrollView addSubview:_imageView];

    _scrollView.contentSize = CGSizeMake(0, CGRectGetMaxY(_imageView.frame) + 16);

    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap1Action:)];
    [_label addGestureRecognizer:tap1];

    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap2Action:)];
    [_imageView addGestureRecognizer:tap2];

    [self setupTableView];
}

- (void)setupTableView {
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_scrollView.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)/2)];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.sensorsAnalyticsDelegate = self;
    [self.view addSubview:_tableView];

    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
}

- (void)firstAction:(UIButton *)sender {
    NSLog(@"%@ Touch Up Inside", sender.currentTitle);
}

- (void)secondAction:(UIButton *)sender {
    NSLog(@"%@ Touch Up Inside", sender.currentTitle);
}

- (void)stepperAction:(UIStepper *)sender {
    NSLog(@"UIStepper on:%f", sender.value);
}

- (void)sliderAction:(UISlider *)sender {
    NSLog(@"UISlider on:%f", sender.value);
}

- (void)switchAction:(UISwitch *)sender {
    NSLog(@"UISwitch on:%d", sender.isOn);
}

- (void)segmentedAction:(UISegmentedControl *)sender {
    NSLog(@"UISwitch on:%ld", sender.selectedSegmentIndex);
}

- (void)labelTouchUpInside:(UITapGestureRecognizer *)recognizer {
    UILabel *label = (UILabel *)recognizer.view;
    NSLog(@"%@被点击了", label.text);
}

- (void)imageViewTouchUpInside:(UITapGestureRecognizer *)recognizer {
    NSLog(@"UIImageView被点击了");
}

- (void)tap1Action:(UIGestureRecognizer *)sender {
    UILabel *label = (UILabel *)sender.view;
    NSLog(@"%@被点击了", label.text);
}

- (void)tap2Action:(UIGestureRecognizer *)sender {
    NSLog(@"UIImageView被点击了");
}

#pragma mark -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"Section: %ld, Row: %ld", indexPath.section, indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%@", indexPath);
}

#pragma mark - SAUIViewAutoTrackDelegate
- (NSDictionary *)sensorsAnalytics_tableView:(UITableView *)tableView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath {
    return arc4random()%2 == 0 ? nil : @{@"SAUIViewAutoTrackDelegate": @"Sensors Data"};
}

@end
