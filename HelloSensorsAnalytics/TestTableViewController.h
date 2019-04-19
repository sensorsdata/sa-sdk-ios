//
//  TestTableViewController.h
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
