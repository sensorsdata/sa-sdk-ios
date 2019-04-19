//
//  TestTableViewController.m
//  HelloSensorsAnalytics
//
//  Created by 王灼洲 on 2017/10/16.
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
#import "SensorsAnalyticsSDK.h"
@interface SATableHeaderFooterView : UITableViewHeaderFooterView
@property(nonatomic,assign)NSUInteger section;
@property(nonatomic,weak)UITableView *tablView;
@property(nonatomic,strong)UIButton *backButton;
@property(nonatomic,strong)NSString *title;
@property(nonatomic,copy)void (^clickHeader)(UITableView *tableView, NSUInteger section);
@end
@implementation SATableHeaderFooterView
-(instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.contentView addSubview:self.backButton];
        [self.backButton addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
-(void)click:(UIButton *)button {
    if (self.clickHeader) {
        self.clickHeader(self.tablView, self.section);
    }
    NSLog(@"section: %@",[self performSelector:@selector(sa_section)]);
}
//-(NSString *)title {
//    return @"title";
//}
-(void)layoutSubviews{
    [super layoutSubviews];
    self.contentView.frame = self.bounds;
    self.backButton.frame = self.contentView.bounds;
    [self.backButton setTitleColor:UIColor.redColor forState:UIControlStateNormal];
}
@end

@interface TestTableViewController ()

@end

@implementation TestTableViewController

-(NSArray *)dataArray{
    if (!_dataArray) {
        _dataArray = @[@[@"section00",@"section01"],@[@"section10"],@[@"section10",@"section11"]];
    }
    return _dataArray;
}

-(NSArray *)dataArray_1{
    if (!_dataArray_1) {
        NSMutableArray *arr = [NSMutableArray array];
        for (int i=0; i<100; i++) {
            NSString *title = [[NSString alloc]initWithFormat:@"index_%i",i];
            [arr addObject:title];
        }
        _dataArray_1 = arr;
    }
    return _dataArray_1;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGRect frame = self.view.bounds;
    CGRect table_frame = CGRectMake(0, 0, frame.size.width, frame.size.height/2.0);
    CGRect table_1_frame = CGRectMake(0, frame.size.height/2.0, frame.size.width, frame.size.height/2.0);

    self.tableView = [[UITableView alloc]initWithFrame:table_frame style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sensorsAnalyticsViewID = @"tableView1";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.tableView registerClass:SATableHeaderFooterView.class forHeaderFooterViewReuseIdentifier:@"SATableHeaderFooterView"];
    [self.view addSubview:self.tableView];
    SATableHeaderFooterView *headerView = [[SATableHeaderFooterView alloc]initWithReuseIdentifier:nil];
    headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 60);
    [headerView.backButton setTitle:@"tableHeaderView" forState:UIControlStateNormal];
    headerView.tablView = self.tableView;
    headerView.clickHeader = ^(UITableView *tableView, NSUInteger section) {

    };
    headerView.backButton.backgroundColor = UIColor.redColor;
    self.tableView.tableHeaderView = headerView;
    SATableHeaderFooterView *footerView = [[SATableHeaderFooterView alloc]initWithReuseIdentifier:nil];
    footerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 60);
    [footerView.backButton setTitle:@"tableFooterView" forState:UIControlStateNormal];
    footerView.tablView = self.tableView;
    footerView.clickHeader = ^(UITableView *tableView, NSUInteger section) {

    };
    footerView.backButton.backgroundColor = UIColor.redColor;
    self.tableView.tableFooterView = footerView;

//    UILabel *header = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 60)];
//    header.userInteractionEnabled = YES;
//    [header addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(headerClick:)]];
////    header.text = @"header";
//
//    self.tableView.tableHeaderView = header;
//
//    UILabel *footer = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 60)];
//    footer.userInteractionEnabled = YES;
//    [footer addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(headerClick:)]];
////    footer.text = @"footer";
//    self.tableView.tableFooterView = footer;

    self.tableView_1 = [[UITableView alloc]initWithFrame:table_1_frame style:UITableViewStylePlain];
    self.tableView_1.delegate = self;
    self.tableView_1.dataSource = self;
    self.tableView_1.sensorsAnalyticsViewID = @"tableView2";
    [self.tableView_1 registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
//    [self.tableView_1 registerClass:SATableHeaderFooterView.class forHeaderFooterViewReuseIdentifier:@"SATableHeaderFooterView"];

    [self.view addSubview:self.tableView_1];

    self.view.backgroundColor = [UIColor whiteColor];
}
-(void)headerClick:(UITapGestureRecognizer *)gesture{

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        return self.dataArray.count;
    }
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return [self.dataArray[section] count];
    }
    return self.dataArray_1.count;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }

    if (tableView == self.tableView) {
        cell.textLabel.text = self.dataArray[indexPath.section][indexPath.row];
    }else{
        cell.textLabel.text = self.dataArray_1[indexPath.row];
    }
    return cell;
}
//-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    NSString *title = nil;
//    if (tableView == self.tableView) {
//        title = [NSString stringWithFormat:@"table :section %ld",(long)section];
//    }else{
//        title = [NSString stringWithFormat:@"table_1 :section %ld",(long)section];
//    }
//    return title;
//
//}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    SATableHeaderFooterView *sectionFooterView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"SATableHeaderFooterView"];
    if (sectionFooterView == nil) {
        sectionFooterView = [[SATableHeaderFooterView alloc]initWithReuseIdentifier:@"SATableHeaderFooterView"];
    }
    [sectionFooterView.backButton setTitle:[NSString stringWithFormat:@"footer_section_%ld",(long)section] forState:UIControlStateNormal];
//    sectionFooterView.backgroundColor = UIColor.blackColor;
    sectionFooterView.section = section;
    sectionFooterView.tablView = tableView;
    sectionFooterView.clickHeader = ^(UITableView *tableView, NSUInteger section) {

    };
    return sectionFooterView;
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SATableHeaderFooterView *sectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"SATableHeaderFooterView"];
    if (sectionHeaderView == nil) {
        sectionHeaderView = [[SATableHeaderFooterView alloc]initWithReuseIdentifier:@"SATableHeaderFooterView"];
    }
    [sectionHeaderView.backButton setTitle:[NSString stringWithFormat:@"header_section_%ld",(long)section] forState:UIControlStateNormal];
//    sectionHeaderView.backgroundColor = UIColor.blueColor;
    sectionHeaderView.section = section;
    sectionHeaderView.tablView = tableView;
    sectionHeaderView.clickHeader = ^(UITableView *tableView, NSUInteger section) {

    };
    return sectionHeaderView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60;
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 60;
}
-(void)dealloc {

}
@end


@implementation TestTableViewController_A

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}


@end
@implementation TestTableViewController_B

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}


@end
