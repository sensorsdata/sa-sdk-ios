//
//  TestTableViewController.h
//  HelloSensorsAnalytics
//
//  Created by ziven.mac on 2017/10/16.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestTableViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong)UITableView *tableView;
@property(nonatomic,strong)NSArray *dataArray;
@property(nonatomic,strong)UITableView *tableView_1;
@property(nonatomic,strong)NSArray *dataArray_1;
@end

@interface  TestTableViewController_A: TestTableViewController

@end
@interface  TestTableViewController_B: TestTableViewController

@end
