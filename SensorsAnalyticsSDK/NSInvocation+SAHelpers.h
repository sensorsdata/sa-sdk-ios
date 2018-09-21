//  SASwizzler.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/20/16
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (SAHelpers)

- (void)sa_setArgumentsFromArray:(NSArray *)argumentArray;
- (id)sa_returnValue;

@end
