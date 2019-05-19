//
//  DemoController.h
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

#ifndef DemoController_h
#define DemoController_h

#import <UIKit/UIKit.h>
#import <SensorsAnalyticsSDK/SensorsAnalyticsSDK.h>

@interface DemoController : UITableViewController<SAScreenAutoTracker, SAUIViewAutoTrackDelegate, UIActionSheetDelegate>

@end

#endif /* DemoController_h */
