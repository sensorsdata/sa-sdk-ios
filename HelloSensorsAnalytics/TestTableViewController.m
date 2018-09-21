//
//  TestTableViewController.m
//  HelloSensorsAnalytics
//
//  Created by ziven.mac on 2017/10/16.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import "TestTableViewController.h"
#import "SensorsAnalyticsSDK.h"

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
        _dataArray_1 = @[@"index_0",@"index_1",@"index_2"];
        
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
    [self.view addSubview:self.tableView];
    
    self.tableView_1 = [[UITableView alloc]initWithFrame:table_1_frame style:UITableViewStylePlain];
    self.tableView_1.delegate = self;
    self.tableView_1.dataSource = self;
    self.tableView_1.sensorsAnalyticsViewID = @"tableView2";
    [self.tableView_1 registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView_1];
    self.view.backgroundColor = [UIColor whiteColor ];
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
    if (tableView == self.tableView) {
        cell.textLabel.text = self.dataArray[indexPath.section][indexPath.row];

    }else{
        cell.textLabel.text = self.dataArray_1[indexPath.row];

    }
    return cell;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    if (tableView == self.tableView) {
        title = [NSString stringWithFormat:@"table :section %ld",(long)section];

    }else{
        
        title = [NSString stringWithFormat:@"table_1 :section %ld",(long)section];
    }
    return title;

}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}
-(void)dealloc {
    
}
@end
