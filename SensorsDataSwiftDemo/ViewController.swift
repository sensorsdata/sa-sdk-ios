//
//  ViewController.swift
//  SensorsDataSwiftDemo
//
//  Created by 王灼洲 on 2017/11/9.
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

import UIKit

class ViewController: UIViewController{

    var tableView:UITableView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "ViewController"
        self.navigationController?.navigationBar.backgroundColor = UIColor.blue
        self.view.backgroundColor = UIColor.white
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
 
}

extension ViewController:UITableViewDelegate{
    
    
}


