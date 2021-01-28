//
//  SAVisualizedAutoTrackConnection.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/4.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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

#import <Foundation/Foundation.h>

@protocol SAVisualizedMessage;

@interface SAVisualizedConnection : NSObject

@property (nonatomic, readonly) BOOL connected;

- (instancetype)initWithURL:(NSURL *)url;

- (void)sendMessage:(id<SAVisualizedMessage>)message;
- (void)startConnectionWithFeatureCode:(NSString *)featureCode url:(NSString *)urlStr;
- (void)close;

// 是否正在进行可视化全埋点上传页面信息
- (BOOL)isVisualizedConnecting;
@end
