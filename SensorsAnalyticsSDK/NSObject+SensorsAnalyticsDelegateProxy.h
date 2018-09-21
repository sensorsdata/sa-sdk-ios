//
//  NSObject+SensorsAnalyticsDelegateProxy.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WKWebView.h>

@class SADelegateProxy;
@interface NSObject (SensorsAnalyticsDelegateProxy)
@property (nonatomic,strong) SADelegateProxy *sensorsAnalyticsDelegateProxy;
@end

@interface UITableView (SensorsAnalyticsDelegateProxy)
@end

@interface UICollectionView (SensorsAnalyticsDelegateProxy)
@end
