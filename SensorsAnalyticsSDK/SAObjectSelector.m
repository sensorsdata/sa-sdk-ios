//
//  SAObjectSelector.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/20/16
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#import "SALogger.h"
#import "SAObjectSelector.h"

@interface SAObjectFilter : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSPredicate *predicate;
@property (nonatomic, strong) NSNumber *index;
@property (nonatomic, assign) BOOL unique;
@property (nonatomic, assign) BOOL nameOnly;

- (NSArray *)apply:(NSArray *)views;
- (NSArray *)applyReverse:(NSArray *)views;
- (BOOL)appliesTo:(NSObject *)view;
- (BOOL)appliesToAny:(NSArray *)views;

@end

@interface SAObjectSelector () {
    NSCharacterSet *_classAndPropertyChars;
    NSCharacterSet *_separatorChars;
    NSCharacterSet *_predicateStartChar;
    NSCharacterSet *_predicateEndChar;
    NSCharacterSet *_flagStartChar;
    NSCharacterSet *_flagEndChar;

}

@property (nonatomic, strong) NSScanner *scanner;
@property (nonatomic, strong) NSArray *filters;

@end

@implementation SAObjectSelector

+ (SAObjectSelector *)objectSelectorWithString:(NSString *)string {
    return [[SAObjectSelector alloc] initWithString:string];
}

- (instancetype)initWithString:(NSString *)string {
    if (self = [super init]) {
        _string = string;
        _scanner = [NSScanner scannerWithString:string];
        [_scanner setCharactersToBeSkipped:nil];
        _separatorChars = [NSCharacterSet characterSetWithCharactersInString:@"/"];
        _predicateStartChar = [NSCharacterSet characterSetWithCharactersInString:@"["];
        _predicateEndChar = [NSCharacterSet characterSetWithCharactersInString:@"]"];
        _classAndPropertyChars = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.*"];
        _flagStartChar = [NSCharacterSet characterSetWithCharactersInString:@"("];
        _flagEndChar = [NSCharacterSet characterSetWithCharactersInString:@")"];

        NSMutableArray *filters = [NSMutableArray array];
        SAObjectFilter *filter;
        BOOL isRoot = true;
        while((filter = [self nextFilter])) {
            // RootViewController不写入filters中
            if (isRoot) {
                isRoot = false;
                continue;
            }
            [filters addObject:filter];
        }
        self.filters = [filters copy];
    }
    return self;
}

/*
 Starting at the root object, try and find an object
 in the view/controller tree that matches this selector.
*/

- (NSArray *)selectFromRoot:(id)root {
    return [self selectFromRoot:root evaluatingFinalPredicate:YES];
}

- (NSArray *)fuzzySelectFromRoot:(id)root {
    return [self selectFromRoot:root evaluatingFinalPredicate:NO];
}

- (NSArray *)selectFromRoot:(id)root evaluatingFinalPredicate:(BOOL)finalPredicate {
    NSArray *views = @[];
    if (root) {
        views = @[root];

        for (NSUInteger i = 0, n = [_filters count]; i < n; i++) {
            SAObjectFilter *filter = _filters[i];
            filter.nameOnly = (i == n-1 && !finalPredicate);
            views = [filter apply:views];
            if ([views count] == 0) {
                break;
            }
        }
    }
    return views;
}


/*
 Starting at a leaf node, determine if it would be selected
 by this selector starting from the root object given.
 */

- (BOOL)isLeafSelected:(id)leaf fromRoot:(id)root {
    return [self isLeafSelected:leaf fromRoot:root evaluatingFinalPredicate:YES];
}

- (BOOL)fuzzyIsLeafSelected:(id)leaf fromRoot:(id)root {
    return [self isLeafSelected:leaf fromRoot:root evaluatingFinalPredicate:NO];
}

- (BOOL)isLeafSelected:(id)leaf fromRoot:(id)root evaluatingFinalPredicate:(BOOL)finalPredicate {
    BOOL isSelected = YES;
    NSArray *views = @[leaf];
    NSUInteger n = [_filters count], i = n;
    while(i--) {
        SAObjectFilter *filter = _filters[i];
        filter.nameOnly = (i == n-1 && !finalPredicate);
        if (![filter appliesToAny:views]) {
            isSelected = NO;
            break;
        }
        views = [filter applyReverse:views];
        if ([views count] == 0) {
            break;
        }
    }
    return isSelected && [views indexOfObject:root] != NSNotFound;
}

- (SAObjectFilter *)nextFilter {
    SAObjectFilter *filter;
    if ([_scanner scanCharactersFromSet:_separatorChars intoString:nil]) {
        NSString *name;
        filter = [[SAObjectFilter alloc] init];
        if ([_scanner scanCharactersFromSet:_classAndPropertyChars intoString:&name]) {
            filter.name = name;
        } else {
            filter.name = @"*";
        }
        if ([_scanner scanCharactersFromSet:_flagStartChar intoString:nil]) {
            NSString *flags;
            [_scanner scanUpToCharactersFromSet:_flagEndChar intoString:&flags];
            for (NSString *flag in[flags componentsSeparatedByString:@"|"]) {
                if ([flag isEqualToString:@"unique"]) {
                    filter.unique = YES;
                }
            }
        }
        if ([_scanner scanCharactersFromSet:_predicateStartChar intoString:nil]) {
            NSString *predicateFormat;
            NSInteger index = 0;
            if ([_scanner scanInteger:&index] && [_scanner scanCharactersFromSet:_predicateEndChar intoString:nil]) {
                filter.index = @((NSUInteger)index);
            } else {
                [_scanner scanUpToCharactersFromSet:_predicateEndChar intoString:&predicateFormat];
                @try {
                    NSPredicate *parsedPredicate = [NSPredicate predicateWithFormat:predicateFormat];
                    filter.predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                        @try {
                            return [parsedPredicate evaluateWithObject:evaluatedObject substitutionVariables:bindings];
                        }
                        @catch (NSException *exception) {
                            return false;
                        }
                    }];
                }
                @catch (NSException *exception) {
                    filter.predicate = [NSPredicate predicateWithValue:NO];
                }

                [_scanner scanCharactersFromSet:_predicateEndChar intoString:nil];
            }
        }
    }
    return filter;
}

- (Class)selectedClass {
    if ([_filters count] > 0) {
        return NSClassFromString(((SAObjectFilter *)_filters[[_filters count] - 1]).name);
    }
    return nil;
}

- (NSString *)description {
    return self.string;
}

@end

@implementation SAObjectFilter

- (instancetype)init {
    if((self = [super init])) {
        self.unique = NO;
        self.nameOnly = NO;
    }
    return self;
}

/*
 Apply this filter to the views, returning all of their children
 that match this filter's class / predicate pattern
 */
- (NSArray *)apply:(NSArray *)views {
    NSMutableArray *result = [NSMutableArray array];
    Class class = NSClassFromString(_name);
    if (class || [_name isEqualToString:@"*"]) {
        // Select all children
        for (NSObject *view in views) {
            NSArray *children = [self getChildrenOfObject:view ofType:class];
            if (_index && [_index unsignedIntegerValue] < [children count]) {
                // Indexing can only be used for subviews of UIView
                if ([view isKindOfClass:[UIView class]]) {
                    children = @[children[[_index unsignedIntegerValue]]];
                } else {
                    children = @[];
                }
            }
            [result addObjectsFromArray:children];
        }
    }

    if (!self.nameOnly) {
        // If unique is set and there are more than one, return nothing
        if(self.unique && [result count] != 1) {
            return @[];
        }
        // Filter any resulting views by predicate
        if (self.predicate) {
            return [result filteredArrayUsingPredicate:self.predicate];
        }
    }
    return [result copy];
}

/*
 Apply this filter to the views. For any view that
 matches this filter's class / predicate pattern, return
 its parents.
 */
- (NSArray *)applyReverse:(NSArray *)views {
    NSMutableArray *result = [NSMutableArray array];
    for (NSObject *view in views) {
        if ([self appliesTo:view]) {
            [result addObjectsFromArray:[self getParentsOfObject:view]];
        }
    }
    return [result copy];
}

/*
 Returns whether the given view would pass this filter.
 */
- (BOOL)appliesTo:(NSObject *)view {
    return (([self.name isEqualToString:@"*"] || [view isKindOfClass:NSClassFromString(self.name)])
            && (self.nameOnly || (
                (!self.predicate || [_predicate evaluateWithObject:view])
                && (!self.index || [self isView:view siblingNumber:[_index integerValue]])
                && (!(self.unique) || [self isView:view oneOfNSiblings:1])))
            );
}

/*
 Returns whether any of the given views would pass this filter
 */
- (BOOL)appliesToAny:(NSArray *)views {
    for (NSObject *view in views) {
        if ([self appliesTo:view]) {
            return YES;
        }
    }
    return NO;
}

/*
 Returns true if the given view is at the index given by number in
 its parent's subviews. The view's parent must be of type UIView
 */

- (BOOL)isView:(NSObject *)view siblingNumber:(NSInteger)number {
    return [self isView:view siblingNumber:number of:-1];
}

- (BOOL)isView:(NSObject *)view oneOfNSiblings:(NSInteger)number {
    return [self isView:view siblingNumber:-1 of:number];
}

- (BOOL)isView:(NSObject *)view siblingNumber:(NSInteger)index of:(NSInteger)numSiblings {
    NSArray *parents = [self getParentsOfObject:view];
    for (NSObject *parent in parents) {
        if ([parent isKindOfClass:[UIView class]]) {
            NSArray *siblings = [self getChildrenOfObject:parent ofType:NSClassFromString(_name)];
            if ((index < 0 || ((NSUInteger)index < [siblings count] && siblings[(NSUInteger)index] == view))
                && (numSiblings < 0 || [siblings count] == (NSUInteger)numSiblings)) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSArray *)getParentsOfObject:(NSObject *)obj {
    NSMutableArray *result = [NSMutableArray array];
    if ([obj isKindOfClass:[UIView class]]) {
        if ([(UIView *)obj superview]) {
            [result addObject:[(UIView *)obj superview]];
        }
        // For UIView, nextResponder should be its controller or its superview.
        if ([(UIView *)obj nextResponder] && [(UIView *)obj nextResponder] != [(UIView *)obj superview]) {
            [result addObject:[(UIView *)obj nextResponder]];
        }
    } else if ([obj isKindOfClass:[UIViewController class]]) {
        if ([(UIViewController *)obj parentViewController]) {
            [result addObject:[(UIViewController *)obj parentViewController]];
        }
        if ([(UIViewController *)obj presentingViewController]) {
            [result addObject:[(UIViewController *)obj presentingViewController]];
        }
        if ([UIApplication sharedApplication].keyWindow.rootViewController == obj) {
            //TODO is there a better way to get the actual window that has this VC
            [result addObject:[UIApplication sharedApplication].keyWindow];
        }
    }
    return [result copy];
}

- (NSArray *)getChildrenOfObject:(NSObject *)obj ofType:(Class)class {
    NSMutableArray *children = [NSMutableArray array];
    // A UIWindow is also a UIView, so we could in theory follow the subviews chain from UIWindow, but
    // for now we only follow rootViewController from UIView.
    if ([obj isKindOfClass:[UIWindow class]] && [((UIWindow *)obj).rootViewController isKindOfClass:class]) {
        [children addObject:((UIWindow *)obj).rootViewController];
    } else if ([obj isKindOfClass:[UIView class]]) {
        // For UIViews, only add subviews, nothing else.
        // The ordering of this result is critical to being able to
        // apply the index filter.
        for (NSObject *child in [(UIView *)obj subviews]) {
            if (!class || [child isKindOfClass:class]) {
                [children addObject:child];
            }
        }
    } else if ([obj isKindOfClass:[UIViewController class]]) {
        UIViewController *viewController = (UIViewController *)obj;
        for (NSObject *child in [viewController childViewControllers]) {
            if (!class || [child isKindOfClass:class]) {
                [children addObject:child];
            }
        }
        if (viewController.presentedViewController && (!class || [viewController.presentedViewController isKindOfClass:class])) {
            [children addObject:viewController.presentedViewController];
        }
        if (!class || (viewController.isViewLoaded && [viewController.view isKindOfClass:class])) {
            [children addObject:viewController.view];
        }
    }
    NSArray *result;
    // Reorder the cells in a table view so that they are arranged by y position
    if ([class isSubclassOfClass:[UITableViewCell class]]) {
//        result = [children sortedArrayUsingComparator:^NSComparisonResult(UIView *obj1, UIView *obj2) {
//            if (obj2.frame.origin.y > obj1.frame.origin.y) {
//                return NSOrderedAscending;
//            } else if (obj2.frame.origin.y < obj1.frame.origin.y) {
//                return NSOrderedDescending;
//            }
//            return NSOrderedSame;
//        }];
        result = [children copy];
    } else {
        result = [children copy];
    }
    return result;
}

- (NSString *)description; {
    return [NSString stringWithFormat:@"%@[%@]", self.name, self.index ?: self.predicate];
}

@end
