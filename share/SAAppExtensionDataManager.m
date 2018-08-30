//
//  SAAppExtensionDataManager.m
//  SensorsAnalyticsSDK
//
//  Created by ziven.mac on 2018/1/18.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import "SAAppExtensionDataManager.h"
void *SAAppExtensionQueueTag = &SAAppExtensionQueueTag;
@interface SAAppExtensionDataManager() {
    dispatch_queue_t _appExtensionQueue;
}
@property(nonatomic,strong)dispatch_queue_t appExtensionQueue;

@end
@implementation SAAppExtensionDataManager

+(instancetype)sharedInstance {
    static SAAppExtensionDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SAAppExtensionDataManager alloc]init];
    });
    return manager;
}

-(instancetype)init {
    if (self = [super init]) {
        self.appExtensionQueue = dispatch_queue_create("com.sensorsdata.analytics.appExtensionQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(self.appExtensionQueue, SAAppExtensionQueueTag, &SAAppExtensionQueueTag, NULL);
    }
    return self;
}

-(void)setGroupIdentifierArray:(NSArray *)groupIdentifierArray {
    dispatch_block_t block = ^(){
        self->_groupIdentifierArray = groupIdentifierArray;
    };
    
    if (dispatch_get_specific(SAAppExtensionQueueTag)) {
        block();
    }else{
        dispatch_async(self.appExtensionQueue, block);
    }
}

-(NSArray *)groupIdentifierArray {
   __block  NSArray *groupArray = nil;
    dispatch_block_t block = ^(){
        groupArray = self->_groupIdentifierArray;
    };
    if (dispatch_get_specific(SAAppExtensionQueueTag)) {
        block();
    }else{
        dispatch_sync(self.appExtensionQueue, block);
    }
    return groupArray;
}

#pragma mark -- plistfile
-(NSString *)filePathForApplicationGroupIdentifier:(NSString *)groupIdentifier {
    
    NSAssert([groupIdentifier isKindOfClass:NSString.class], @"[SAAppExtensionDataManager filePathForApplicationGroupIdentifier:]  groupIdentifier is not NSString class.");
    NSAssert(groupIdentifier.length, @"[SAAppExtensionDataManager filePathForApplicationGroupIdentifier:]  groupIdentifier can not be nil or empty.");
    
    if (![groupIdentifier isKindOfClass:NSString.class] || !groupIdentifier.length) {
        return  nil;
    }
    __block  NSString  *filePath = nil;
    dispatch_block_t block = ^(){
        NSURL  *pathUrl = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupIdentifier]URLByAppendingPathComponent:@"sensors_event_data.plist"];
        filePath = pathUrl.path;
    };
    if (dispatch_get_specific(SAAppExtensionQueueTag)) {
        block();
    }else{
        dispatch_sync(self.appExtensionQueue, block);
    }
    return filePath;
}

-(NSUInteger)fileDataCountForGroupIdentifier:(NSString *)groupIdentifier {
    
    NSAssert([groupIdentifier isKindOfClass:NSString.class], @"[SAAppExtensionDataManager fileDataCountForGroupIdentifier:]  groupIdentifier is not NSString class.");
    NSAssert(groupIdentifier.length, @"[SAAppExtensionDataManager fileDataCountForGroupIdentifier:]  groupIdentifier can not be nil or empty .");
    
    if (![groupIdentifier isKindOfClass:NSString.class] || !groupIdentifier.length) {
        return  0;
    }
    
    __block  NSInteger  count = 0;
    dispatch_block_t block = ^(){
        NSString *path = [self filePathForApplicationGroupIdentifier:groupIdentifier];
        NSArray *array = [[NSMutableArray alloc] initWithContentsOfFile:path];
        count = array.count;
    };
    if (dispatch_get_specific(SAAppExtensionQueueTag)) {
        block();
    }else{
        dispatch_sync(self.appExtensionQueue, block);
    }
    return count;
}

-(NSArray *)fileDataArrayWithPath:(NSString *)path limit:(NSUInteger)limit {
    
    NSAssert([path isKindOfClass:NSString.class], @"[SAAppExtensionDataManager fileDataArrayWithPath:limit:]  path is not NSString class.");
    NSAssert(path.length, @"[SAAppExtensionDataManager fileDataArrayWithPath:limit:]  path can not be  or empty.");
    NSAssert(limit>0, @"[SAAppExtensionDataManager fileDataArrayWithPath:limit:]  limit must be greater then zero.");
    
    if (![path isKindOfClass:NSString.class] || !path.length) {
        return  @[];
    }
    if (limit==0) {
        return  @[];
    }
    
    __block NSArray *dataArray = @[];
    dispatch_block_t block = ^(){
        NSArray *array = [[NSArray alloc] initWithContentsOfFile:path];
        if(array.count>=limit){
            array =  [array subarrayWithRange:NSMakeRange(0, limit)];
        }
        dataArray = array;
    };
    if (dispatch_get_specific(SAAppExtensionQueueTag)) {
        block();
    }else{
        dispatch_sync(self.appExtensionQueue, block);
    }
    return dataArray;
}

-(BOOL)writeEvent:(NSString *)eventName properties:(NSDictionary *)properties groupIdentifier:(NSString *)groupIdentifier {
    
    NSAssert([eventName isKindOfClass:NSString.class], @"[SAAppExtensionDataManager writeEvent:properties:groupIdentifier:]  eventName is not NSString class.");
    NSAssert([groupIdentifier isKindOfClass:NSString.class], @"[SAAppExtensionDataManager writeEvent:properties:groupIdentifier:]  groupIdentifier is not NSString class.");
    NSAssert(eventName.length, @"[SAAppExtensionDataManager writeEvent:properties:groupIdentifier:]  eventName can not be nil or empty.");
    NSAssert(groupIdentifier.length, @"[SAAppExtensionDataManager writeEvent:properties:groupIdentifier:]  groupIdentifier can not be nil or empty.");
    NSAssert(([properties isKindOfClass:NSDictionary.class] || properties==nil), @"[SAAppExtensionDataManager writeEvent:properties:groupIdentifier:]  properties is not nil , and it's not NSDictionary class.");

    if (![eventName isKindOfClass:NSString.class] || !eventName.length) {
        return  NO;
    }
    if (![groupIdentifier isKindOfClass:NSString.class] || !groupIdentifier.length) {
        return NO;
    }
    if (properties && ![properties isKindOfClass:NSDictionary.class]) {
        return  NO;
    }
    
    __block BOOL result = NO;
    dispatch_block_t block = ^{
        NSDictionary *event = @{@"event":eventName,@"properties":properties?properties:@{}};
        NSString *path = [self filePathForApplicationGroupIdentifier:groupIdentifier];
        if(![[NSFileManager defaultManager]fileExistsAtPath:path]){
            BOOL suss=   [[NSFileManager defaultManager]createFileAtPath:path contents:nil attributes:nil];
            if (suss) {
                NSLog(@"create plist file success!!!!!!! APPEXtension...");
            }
        }
        NSMutableArray *array = [[NSMutableArray alloc] initWithContentsOfFile:path];
        if (array.count) {
            [array addObject:event];
        }else{
            array = [NSMutableArray arrayWithObject:event];
        }
        NSError  *err = NULL;
        NSData *data= [NSPropertyListSerialization dataWithPropertyList:array
                                                                 format:NSPropertyListBinaryFormat_v1_0
                                                                options:0
                                                                  error:&err];
        if (path && data.length) {
            result =  [ data   writeToFile:path options:NSDataWritingAtomic error:nil];
        }
    };
    if (dispatch_get_specific(SAAppExtensionQueueTag)) {
        block();
    }else{
        dispatch_sync(self.appExtensionQueue, block);
    }
    return result ;
}

-(NSArray *)readAllEventsWithGroupIdentifier:(NSString *)groupIdentifier {
    
    NSAssert([groupIdentifier isKindOfClass:NSString.class], @"[SAAppExtensionDataManager readAllEventsWithGroupIdentifier:]  groupIdentifier is not NSString class.");
    NSAssert(groupIdentifier.length, @"[SAAppExtensionDataManager readAllEventsWithGroupIdentifier:]  groupIdentifier can not be nil or empty.");
    
    if (![groupIdentifier isKindOfClass:NSString.class] || !groupIdentifier.length) {
        return @[];
    }
    __block NSArray *dataArray = @[];
    dispatch_block_t block = ^(){
        NSString *path = [self filePathForApplicationGroupIdentifier:groupIdentifier];
        NSMutableArray *array = [[NSMutableArray alloc] initWithContentsOfFile:path];
        dataArray = array;
    };
    if (dispatch_get_specific(SAAppExtensionQueueTag)) {
        block();
    }else{
        dispatch_sync(self.appExtensionQueue, block);
    }
    return dataArray;
}

-(BOOL)deleteEventsWithGroupIdentifier:(NSString *)groupIdentifier {
    
    NSAssert([groupIdentifier isKindOfClass:NSString.class], @"[SAAppExtensionDataManager deleteEventsWithGroupIdentifier:]  groupIdentifier is not NSString class.");
    NSAssert(groupIdentifier.length, @"[SAAppExtensionDataManager deleteEventsWithGroupIdentifier:]  groupIdentifier can not be nil or empty.");
    
    if (![groupIdentifier isKindOfClass:NSString.class] || !groupIdentifier.length) {
        return NO;
    }
    __block BOOL result = NO;
    dispatch_block_t block = ^{
        NSString *path = [self filePathForApplicationGroupIdentifier:groupIdentifier];
        NSMutableArray *array = [[NSMutableArray alloc] initWithContentsOfFile:path];
        [array removeAllObjects];
        NSData *data= [NSPropertyListSerialization dataWithPropertyList:array
                                                                  format:NSPropertyListBinaryFormat_v1_0
                                                                 options:0
                                                                   error:nil];
      result =  [data   writeToFile:path options:NSDataWritingAtomic error:nil];
    };
    if (dispatch_get_specific(SAAppExtensionQueueTag)) {
        block();
    }else{
        dispatch_sync(self.appExtensionQueue, block);
    }
    return result ;
}

@end
