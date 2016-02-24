//
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <Foundation/Foundation.h>

@interface NSInvocation (SAHelpers)

- (void)sa_setArgumentsFromArray:(NSArray *)argumentArray;
- (id)sa_returnValue;

@end
