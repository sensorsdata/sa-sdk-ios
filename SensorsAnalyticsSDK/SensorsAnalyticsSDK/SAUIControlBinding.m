//
//  SAUIControlBinding.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/20/16
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//

#import "SASwizzler.h"
#import "SAUIControlBinding.h"
#import "SALogger.h"

@interface SAUIControlBinding()

// 已监听的控件的字典
@property (nonatomic, copy) NSHashTable *appliedTo;
// 已触发前置事件的控件的字典
@property (nonatomic, copy) NSHashTable *verified;

- (void)stopOnView:(UIView *)view;

@end

@implementation SAUIControlBinding

+ (NSString *)typeName {
    return @"UIControl";
}

+ (SAEventBinding *)bindingWithJSONObject:(NSDictionary *)object {
    NSString *path = object[@"path"];
    if (![path isKindOfClass:[NSString class]] || [path length] < 1) {
        SAError(@"must supply a view path to bind by");
        return nil;
    }

    NSString *eventName = object[@"event_name"];
    if (![eventName isKindOfClass:[NSString class]] || [eventName length] < 1 ) {
        SAError(@"binding requires an event name");
        return nil;
    }
    
    NSInteger triggerId = [[object objectForKey:@"trigger_id"] integerValue];
    BOOL deployed = [[object objectForKey:@"deployed"] boolValue];

    if (!(object[@"control_event"] && ([object[@"control_event"] unsignedIntegerValue] & UIControlEventAllEvents))) {
        SAError(@"must supply a valid UIControlEvents value for control_event");
        return nil;
    }

    UIControlEvents verifyEvent = object[@"verify_event"] ? [object[@"verify_event"] unsignedIntegerValue] : 0;
    return [[SAUIControlBinding alloc] initWithEventName:eventName
                                            andTriggerId:triggerId
                                                  onPath:path
                                              isDeployed:deployed
                                        withControlEvent:[object[@"control_event"] unsignedIntegerValue]
                                          andVerifyEvent:verifyEvent];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
+ (SAEventBinding *)bindngWithJSONObject:(NSDictionary *)object {
    return [self bindingWithJSONObject:object];
}
#pragma clang diagnostic pop

- (instancetype)initWithEventName:(NSString *)eventName
                     andTriggerId:(NSInteger)triggerId
                           onPath:(NSString *)path
                       isDeployed:(BOOL)deployed
                 withControlEvent:(UIControlEvents)controlEvent
                   andVerifyEvent:(UIControlEvents)verifyEvent {
    if (self = [super initWithEventName:eventName andTriggerId:triggerId onPath:path isDeployed:deployed]) {
        [self setSwizzleClass:[UIControl class]];
        _controlEvent = controlEvent;
        _verifyEvent = verifyEvent;

        [self resetAppliedTo];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Event Binding: '%@' for '%@'", [self eventName], [self path]];
}

- (void)resetAppliedTo {
    self.verified = [NSHashTable hashTableWithOptions:(NSHashTableWeakMemory|NSHashTableObjectPointerPersonality)];
    self.appliedTo = [NSHashTable hashTableWithOptions:(NSHashTableWeakMemory|NSHashTableObjectPointerPersonality)];
}

#pragma mark -- Executing Actions

- (void)execute {
    if (!self.running) {
        void (^executeBlock)(id, SEL) = ^(id view, SEL command) {
            NSArray *objects;
            //NSObject *root = [[UIApplication sharedApplication] keyWindow].rootViewController;
            NSObject *root = [[UIApplication sharedApplication].delegate window].rootViewController;
            if (view && [self.appliedTo containsObject:view]) {
                if (![self.path fuzzyIsLeafSelected:view fromRoot:root]) {
                    [self stopOnView:view];
                    [self.appliedTo removeObject:view];
                }
            } else {
                // select targets based off path
                if (view) {
                    if ([self.path fuzzyIsLeafSelected:view fromRoot:root]) {
                        objects = @[view];
                    } else {
                        objects = @[];
                    }
                } else {
                    objects = [self.path fuzzySelectFromRoot:root];
                }

                for (UIControl *control in objects) {
                    if ([control isKindOfClass:[UIControl class]]) {
                        UIControlEvents verifyEvent = [self getPreVerifyEventForClass:control
                                                                      withVerifyEvent:self.verifyEvent
                                                                      andControlEvent:self.controlEvent];
                        
                        SADebug(@"%@ event binding [%d, %d on '%@' for %@] executed.",
                                self, self.controlEvent, verifyEvent, self.path.string, [control class]);
                        
                        if (verifyEvent != 0 && verifyEvent != self.controlEvent) {
                            [control addTarget:self
                                        action:@selector(caojiangPreVerify:forEvent:)
                              forControlEvents:verifyEvent];
                        }

                        [control addTarget:self
                                    action:@selector(caojiangEventAction:forEvent:)
                          forControlEvents:self.controlEvent];
                        [self.appliedTo addObject:control];
                    }
                }
            }
        };

        executeBlock(nil, _cmd);

        [SASwizzler swizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                            onClass:self.swizzleClass
                          withBlock:executeBlock
                              named:self.name];
        [SASwizzler swizzleSelector:NSSelectorFromString(@"didMoveToSuperview")
                            onClass:self.swizzleClass
                          withBlock:executeBlock
                              named:self.name];

        self.running = true;
    }
}

- (void)stop {
    if (self.running) {
        // remove what has been swizzled
        [SASwizzler unswizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                            onClass:self.swizzleClass
                              named:self.name];
        [SASwizzler unswizzleSelector:NSSelectorFromString(@"didMoveToSuperview")
                            onClass:self.swizzleClass
                              named:self.name];

        // remove target-action pairs
        @try {
        NSArray *allObjects = [NSArray arrayWithArray:[self.appliedTo allObjects]];
            for (UIControl *control in allObjects) {
                if (control && [control isKindOfClass:[UIControl class]]) {
                    [self stopOnView:control];
                }
            }
        } @catch (NSException *exception) {
            SADebug(@"stop error: %@", exception);
        }
        [self resetAppliedTo];
        self.running = false;
    }
}

- (void)stopOnView:(UIControl *)control {
    UIControlEvents verifyEvent = [self getPreVerifyEventForClass:control
                                                  withVerifyEvent:self.verifyEvent
                                                  andControlEvent:self.controlEvent];
    
    if (verifyEvent != 0 && verifyEvent != self.controlEvent) {
        [control removeTarget:self
                    action:@selector(caojiangPreVerify:forEvent:)
          forControlEvents:verifyEvent];
    }
    [control removeTarget:self
                action:@selector(caojiangEventAction:forEvent:)
      forControlEvents:self.controlEvent];
}

- (UIControlEvents) getPreVerifyEventForClass:(UIControl *)control
                   withVerifyEvent:(UIControlEvents)verifyEvent
                   andControlEvent:(UIControlEvents)controlEvent {
    if (verifyEvent == 0) {
        if (controlEvent & UIControlEventAllTouchEvents) {
            if ([control isKindOfClass:[UISlider class]] || [control isKindOfClass:[UISwitch class]]) {
                return UIControlEventValueChanged;
            } else {
                return UIControlEventTouchDown;
            }
        } else if (controlEvent & UIControlEventAllEditingEvents) {
            return UIControlEventEditingDidBegin;
        }
    }
    return verifyEvent;
}

#pragma mark -- To execute for Target-Action event firing

- (BOOL)verifyControlMatchesPath:(id)control {
    NSObject *root = [[UIApplication sharedApplication] keyWindow].rootViewController;
    return [self.path isLeafSelected:control fromRoot:root];
}

- (void)caojiangPreVerify:(id)sender forEvent:(UIEvent *)event {
    if ([self verifyControlMatchesPath:sender]) {
        [self.verified addObject:sender];
    } else {
        [self.verified removeObject:sender];
    }
}

- (void)caojiangEventAction:(id)sender forEvent:(UIEvent *)event {
    UIControlEvents verifyEvent = [self getPreVerifyEventForClass:sender
                                                  withVerifyEvent:self.verifyEvent
                                                  andControlEvent:self.controlEvent];
    BOOL shouldTrack = NO;
    if (verifyEvent != 0 && verifyEvent != self.controlEvent) {
        shouldTrack = [self.verified containsObject:sender];
    } else {
        shouldTrack = [self verifyControlMatchesPath:sender];
    }
    if (shouldTrack) {
        [self track:[self eventName] withProperties:nil];
    }
}

#pragma mark -- NSCoder

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _controlEvent = [[aDecoder decodeObjectForKey:@"controlEvent"] unsignedIntegerValue];
        _verifyEvent = [[aDecoder decodeObjectForKey:@"verifyEvent"] unsignedIntegerValue];
        
        [self setSwizzleClass:[UIControl class]];
        [self resetAppliedTo];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:@(_controlEvent) forKey:@"controlEvent"];
    [aCoder encodeObject:@(_verifyEvent) forKey:@"verifyEvent"];
}

@end
