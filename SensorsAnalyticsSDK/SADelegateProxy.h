//
//  SADelegateProxy.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SADelegateProxy : NSProxy
@property(nonatomic,weak)id target;
+(instancetype)proxyWithTableView:(id)target;
+(instancetype)proxyWithCollectionView:(id)target;
@end
