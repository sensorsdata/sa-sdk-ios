//
//  SensorsAnalyticsSDK.m
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/1.
//  Copyright (c) 2015年 SensorsData. All rights reserved.
//

#include <sys/sysctl.h>

#import <AdSupport/ASIdentifierManager.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>

#import "JSONUtil.h"
#import "LFCGzipUtility.h"
#import "MessageQueueBySqlite.h"
#import "NSData+MPBase64.h"
#import "SALogger.h"
#import "SensorsAnalyticsException.h"




#import "SensorsAnalyticsSDK.h"

#define VERSION @"1.2.0"

@interface SensorsAnalyticsSDK()
// 在内部，重新声明成可读写的
@property (atomic, strong) SensorsAnalyticsPeople *people;
@property (atomic, strong) NSString *serverURL;
@property (atomic, copy) NSString *distinctId;
@property (nonatomic, strong) dispatch_queue_t serialQueue;

- (instancetype)initWithServerURL:(NSString *)serverURL andFlushInterval:(NSUInteger)flushInterval;

//- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict withType:(NSString *)type;

@end

@implementation SensorsAnalyticsSDK {
    NSString *_originalId;
    NSUInteger _flushInterval;
    NSDictionary *_automaticProperties;
    NSDictionary *_superProperties;
    CTTelephonyNetworkInfo *_telephonyInfo;
    double _lastFlushTime;
    NSPredicate *_regexTestName;

    MessageQueueBySqlite *_messageQueue;
}



static SensorsAnalyticsSDK *sharedInstance = nil;

- (void)flush {
    dispatch_async(self.serialQueue, ^{
        [self flushQueue];
        _lastFlushTime = [[NSDate date] timeIntervalSince1970];
    });
}

- (BOOL) isValidName : (NSString *) name {
    return [_regexTestName evaluateWithObject:name];
}

/**
 *  @abstract
 *  内部触发的flush，需要根据上次发送时间和网络情况来判断是否发送
 */
- (void) automaticFlush {
    dispatch_async(self.serialQueue, ^{
        // 1. 判断和上次flush之间的时间是否超过了刷新间隔
        if ([[NSDate date] timeIntervalSince1970] - _lastFlushTime < _flushInterval) {
            SADebug(@"flushTime not reach");
            return;
        }
        SADebug(@"flushTime reach");
        // 2. 判断当前网络类型是否是3G/4G/WIFI
        NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
        if ([networkType isEqualToString:@"NULL"] || [networkType isEqualToString:@"2G"]) {
            SADebug(@"network not satisfy");
            return;
        }
        SADebug(@"network satisfy");
        // 3. 发送
        [self flushQueue];
        _lastFlushTime = [[NSDate date] timeIntervalSince1970];
    });
}


/**
 *  @abstract
 *  对要传递的数组进行编码
 *
 *  @param array 要传给服务器的数组
 *
 *  @return 编码后的值
 */
- (NSString *)encodeAPIData:(NSArray *)array {
    // 1. 先完成这一系列Json字符串的拼接
    NSString *jsonString = [NSString stringWithFormat:@"[%@]",[array componentsJoinedByString:@","]];
    SADebug(@"jsonString=%@", jsonString);
    // 2. 使用gzip进行压缩
    NSData *zippedData = [LFCGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    // 3. base64
    NSString *b64String = [zippedData mp_base64EncodedString];
    b64String = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                              (CFStringRef)b64String,
                                                                              NULL,
                                                                              CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                              kCFStringEncodingUTF8));
    return b64String;
}

- (NSString *)filePathForData:(NSString *)data
{
    NSString *filename = [NSString stringWithFormat:@"sensorsanalytics-%@.plist", data];
    NSString *filepath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
    SADebug(@"filepath for %@ is %@", data, filepath);
    return filepath;

}

- (NSURLRequest *)apiRequestWithBody:(NSString *)body {
    NSURL *URL = [NSURL URLWithString:self.serverURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"SensorsAnalytics iOS SDK" forHTTPHeaderField:@"User-Agent"];
    SADebug(@"%@ http request: %@ body: %@", self, URL, body);
    return request;
}


- (void)flushQueue {
    SADebug(@"try to flushQueue");
    NSArray * recordArray = [_messageQueue getFirstRecords:50];
    if (recordArray == nil) {
        @throw [SensorsAnalyticsException exceptionWithName:@"SqliteException" reason:@"getFirstRecords from Message Queue in Sqlite fail" userInfo:nil];
    }
    while ([recordArray count] > 0) {
        NSString *requestData = [self encodeAPIData:recordArray];
        SADebug(@"requestData=%@", requestData);
        NSString *postBody = [NSString stringWithFormat:@"gzip=1&data_list=%@", requestData];
        SADebug(@"%@ flushing %lu of %lu of queue", self, (unsigned long)[recordArray count], (unsigned long)[recordArray count]);
        NSURLRequest *request = [self apiRequestWithBody:postBody];
        NSError *error = nil;
        NSHTTPURLResponse *urlResponse = nil;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
        if (error) {
            SAError(@"%@ network failure: %@", self, error);
            break;
        }
        if([urlResponse statusCode] != 200) {
            SAError(@"%@ api rejected some items, reponse is [%@]", self, urlResponse);
        }
        if (![_messageQueue removeFirstRecords:50]) {
            @throw [SensorsAnalyticsException exceptionWithName:@"SqliteException" reason:@"removeFirstRecords from Message Queue in Sqlite fail" userInfo:nil];
        }
        recordArray = [_messageQueue getFirstRecords:50];
        if (recordArray == nil) {
            @throw [SensorsAnalyticsException exceptionWithName:@"SqliteException" reason:@"getFirstRecords from Message Queue in Sqlite fail" userInfo:nil];
        }
        SADebug(@"flush one batch success, currentCount is %lu", [_messageQueue count]);
    }
    if (![_messageQueue vacuum]) {
        @throw [SensorsAnalyticsException exceptionWithName:@"SqliteException" reason:@"vacuum in Message Queue in Sqlite fail" userInfo:nil];
    }
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict withType:(NSString *)type {
    // 对于type是track和track_signup的数据，它们的event名称是有意义的
    if ([type isEqualToString:@"track"] || [type isEqualToString:@"track_signup"]) {
        if (event == nil || [event length] == 0) {
            @throw [SensorsAnalyticsException exceptionWithName:@"InvalidDataException" reason:@"SensorsAnalytics track called with empty event parameter" userInfo:nil];
        }
        if (![self isValidName:event]) {
            NSString * errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", event];
            @throw [SensorsAnalyticsException exceptionWithName:@"InvalidDataException" reason:errMsg userInfo:nil];
        }

    }
    if (propertieDict) {
        propertieDict = [propertieDict copy];
        [self assertPropertyTypes:propertieDict];
    }
    double epochInterval = [[NSDate date] timeIntervalSince1970] * 1000;
    NSNumber *timeStamp = @(round(epochInterval));
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *p = [NSMutableDictionary dictionary];
        if ([type isEqualToString:@"track"] || [type isEqualToString:@"track_signup"]) {
            // track类型的请求，还是要加上各种公共property
            // 这里注意下顺序，按照优先级从低到高，依次是automaticProperties, superProperties和propertieDict
            [p addEntriesFromDictionary:_automaticProperties];
            [p addEntriesFromDictionary:_superProperties];
            if (propertieDict) {
                [p addEntriesFromDictionary:propertieDict];
            }
            // 是否WIFI是每次track的时候需要判断一次的
            [p setObject:[self ifWifi] forKey:@"$wifi"];

        } else {
            // 对于profile类型的请求，则不需要这些property了
            if (propertieDict) {
                [p addEntriesFromDictionary:propertieDict];
            }
        }
        NSDictionary *e;
        if ([type isEqualToString:@"track_signup"]) {
            e = @{@"event": event, @"properties": [NSDictionary dictionaryWithDictionary:p], @"distinct_id": self.distinctId, @"original_id": _originalId, @"time": timeStamp, @"type": type};
        } else if([type isEqualToString:@"track"]){
            e = @{@"event": event, @"properties": [NSDictionary dictionaryWithDictionary:p], @"distinct_id": self.distinctId, @"time": timeStamp, @"type": type};
        } else {
            // 此时应该都是对Profile的操作
            e = @{@"properties": [NSDictionary dictionaryWithDictionary:p], @"distinct_id": self.distinctId, @"time": timeStamp, @"type": type};
        }
        SADebug(@"%@ queueing event: %@", self, e);
        [_messageQueue addObejct:e];
    });
    if ([type isEqualToString:@"track_signup"]) {
        // 对于track_signup，立刻在队列中添加一个强制flush的指令
        [self flush];
    } else {
        // 对于其它type，则只添加一个检查并决定是否flush的指令
        [self automaticFlush];
    }
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict {
    [self track:event withProperties:propertieDict withType:@"track"];
}

- (void)track:(NSString *)event {
    [self track:event withProperties:nil];
}

- (void)signUp:(NSString *)newDistinctId withProperties:(NSDictionary *)propertieDict {
    dispatch_async(self.serialQueue, ^{
        // 先把之前的distinctId设为originalId
        _originalId = self.distinctId;
        // 更新distinctId
        self.distinctId = newDistinctId;
        [self archiveDistinctId];
    });    
    [self track:@"$SignUp" withProperties:propertieDict withType:@"track_signup"];
}

- (void)signUp:(NSString *)newDistinctId {
    [self signUp:newDistinctId withProperties:nil];
}

- (void)identify:(NSString *)distinctId {
    if (distinctId == nil || distinctId.length == 0) {
        SAError(@"%@ cannot identify blank distinct id: %@", self, distinctId);
        return;
    }
    dispatch_async(self.serialQueue, ^{
        self.distinctId = distinctId;
        [self archiveDistinctId];
    });
}

- (NSString *)IDFA {
    NSString *ifa = nil;
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        ifa = [uuid UUIDString];
    }
    return ifa;
}


- (NSString *)defaultDistinctId{
    // 优先使用IDFA
    NSString *distinctId = [self IDFA];
    
    // 没有IDFA，则尝试使用IDFV
    if (!distinctId && NSClassFromString(@"UIDevice")) {
        distinctId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    // 没有IDFV，则肯定有UUID，此时使用UUID
    if (!distinctId) {
        SADebug(@"%@ error getting device identifier: falling back to uuid", self);
        distinctId = [[NSUUID UUID] UUIDString];
    }
    return distinctId;
}

- (NSString *)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *results = @(answer);
    return results;
}


- (NSString *)libVersion {
    return VERSION;
}

- (NSNumber *)ifWifi {
    NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
    if ([networkType isEqualToString:@"WIFI"]) {
        return @YES;
    } else {
        return @NO;
    }
    
}

- (NSDictionary *)collectAutomaticProperties {
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceModel = [self deviceModel];
    struct CGSize size = [UIScreen mainScreen].bounds.size;
    CTCarrier *carrier = [_telephonyInfo subscriberCellularProvider];
    // Use setValue semantics to avoid adding keys where value can be nil.
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] forKey:@"$app_version"];
    [p setValue:carrier.carrierName forKey:@"$carrier"];
    [p addEntriesFromDictionary:@{
                                  @"$lib": @"iOS",
                                  @"$lib_version": [self libVersion],
                                  @"$manufacturer": @"Apple",
                                  @"$os": [device systemName],
                                  @"$os_version": [device systemVersion],
                                  @"$model": deviceModel,
                                  @"$screen_height": @((NSInteger)size.height),
                                  @"$screen_width": @((NSInteger)size.width)
                                  }];
    return [p copy];
}

- (void)registerSuperProperties:(NSDictionary *)propertyDict {
    propertyDict = [propertyDict copy];
    [self assertPropertyTypes:propertyDict];
    dispatch_async(self.serialQueue, ^{
        // 注意这里的顺序，发生冲突时是以propertyDict为准，所以它是后加入的
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:_superProperties];
        [tmp addEntriesFromDictionary:propertyDict];
        _superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveSuperProperties];
    });
}

- (void)unregisterSuperProperty:(NSString *)property {
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:_superProperties];
        if (tmp[property] != nil) {
            [tmp removeObjectForKey:property];
        }
        _superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveSuperProperties];
    });
    
}

- (void)clearSuperProperties {
    dispatch_async(self.serialQueue, ^{
        _superProperties = @{};
        [self archiveSuperProperties];
    });
}

- (NSDictionary *)currentSuperProperties {
    return [_superProperties copy];
}



- (NSUInteger) currentQueueCount {
    return [_messageQueue count];
}

- (void)unarchive {
    [self unarchiveDistinctId];
    [self unarchiveSuperProperties];
}

- (id)unarchiveFromFile:(NSString *)filePath
{
    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        SADebug(@"%@ unarchived data from %@: %@", self, filePath, unarchivedData);
    }
    @catch (NSException *exception) {
        SAError(@"%@ unable to unarchive data in %@, starting fresh", self, filePath);
        unarchivedData = nil;
    }
    return unarchivedData;
}

- (void)unarchiveDistinctId {
    NSString * archivedDistinctId = (NSString *)[self unarchiveFromFile:[self filePathForData:@"distinct_id"]];
    if (archivedDistinctId == nil) {
        self.distinctId = [self defaultDistinctId];
    } else {
        self.distinctId = archivedDistinctId;
    }
}

- (void)unarchiveSuperProperties {
    NSDictionary * archivedSuperProperties = (NSDictionary *)[self unarchiveFromFile:[self filePathForData:@"super_properties"]];
    if (archivedSuperProperties == nil) {
        _superProperties = [NSDictionary dictionary];
    } else {
        _superProperties = [archivedSuperProperties copy];
    }
}

- (void)archiveDistinctId {
    NSString *filePath = [self filePathForData:@"distinct_id"];
    if (![NSKeyedArchiver archiveRootObject:[[self distinctId] copy] toFile:filePath]) {
        SAError(@"%@ unable to archive distinctId", self);
    }
}

- (void)archiveSuperProperties {
    NSString *filePath = [self filePathForData:@"super_properties"];
    if (![NSKeyedArchiver archiveRootObject:[_superProperties copy] toFile:filePath]) {
        SAError(@"%@ unable to archive superProperties", self);
    }
    
}


- (instancetype)initWithServerURL:(NSString *)serverURL andFlushInterval:(NSUInteger)flushInterval{
    if (serverURL == nil) {
        SAError(@"ServerURL is nil.");
        return nil;
    }
    if ([serverURL length] == 0) {
        SAError(@"ServerURL is nil.");
        return nil;
    }
    if (self = [self init]) {
        self.people = [[SensorsAnalyticsPeople alloc] initWithSDK:self];
        self.serverURL = serverURL;
        _flushInterval = flushInterval;
        _messageQueue = [[MessageQueueBySqlite alloc] initWithFilePath:[self filePathForData:@"message"]];
        if (_messageQueue == nil) {
            @throw [SensorsAnalyticsException exceptionWithName:@"SqliteException" reason:@"init Message Queue in Sqlite fail" userInfo:nil];
        }
        _automaticProperties = [self collectAutomaticProperties];
        _telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        _lastFlushTime = [[NSDate date] timeIntervalSince1970];
        NSString *namePattern = @"^[a-zA-Z_$][a-zA-Z\\d_$]*$";
        _regexTestName = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", namePattern];
        NSString *label = [NSString stringWithFormat:@"com.sensorsdata.%@.%p", @"test", self];
        self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        // 取上一次进程退出时保存的distinctId和superProperties
        [self unarchive];
        [self track:@"$AppStart"];
    }
    return self;
}

+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL andFlushInterval:(NSUInteger)flushInterval {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithServerURL:serverURL andFlushInterval:flushInterval];
    });
    return sharedInstance;
}

+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL {
    return [SensorsAnalyticsSDK sharedInstanceWithServerURL:serverURL andFlushInterval:60];
}

+ (SensorsAnalyticsSDK *)sharedInstance {
    if (sharedInstance == nil) {
        SAError(@"warning sharedInstance called before sharedInstanceWithServerURL:");
    }
    return sharedInstance;
}

- (void)assertPropertyTypes:(NSDictionary *)properties {
    for (id __unused k in properties) {
        // key 必须是NSString
        if (![k isKindOfClass: [NSString class]]) {
            @throw [SensorsAnalyticsException exceptionWithName:@"InvalidDataException" reason:@"Property Key should by NSString" userInfo:nil];
        }
        // key的名称必须符合要求
        if (![self isValidName: k]) {
            @throw [SensorsAnalyticsException exceptionWithName:@"InvalidDataException" reason: [NSString stringWithFormat:@"property name[%@] is not valid", k] userInfo:nil];
        }
        // value的类型必须是有限的积累
        if( ![properties[k] isKindOfClass:[NSString class]] &&
            ![properties[k] isKindOfClass:[NSNumber class]] &&
            ![properties[k] isKindOfClass:[NSNull class]] &&
            ![properties[k] isKindOfClass:[NSSet class]] &&
            ![properties[k] isKindOfClass:[NSDate class]]) {
            NSString * errMsg = [NSString stringWithFormat:@"%@ property values must be NSString, NSNumber, NSSet or NSDate. got: %@ %@", self, [properties[k] class], properties[k]];
            @throw [SensorsAnalyticsException exceptionWithName:@"InvalidDataException" reason:errMsg userInfo:nil];
        }
    }
}

+ (NSString *)getNetWorkStates {
#ifdef SA_UT
    SADebug(@"In unit test, set NetWorkStates to wifi");
    return @"3G";
#endif
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *children = [[[app valueForKeyPath:@"statusBar"]valueForKeyPath:@"foregroundView"]subviews];
    NSString *state = [[NSString alloc]init];
    state = @"NULL";
    int netType = 0;
    //获取到网络返回码
    for (id child in children) {
        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            //获取到状态栏
            netType = [[child valueForKeyPath:@"dataNetworkType"]intValue];
            switch (netType) {
                case 0:
                    state = @"NULL";
                    //无网模式
                    break;
                case 1:
                    state = @"2G";
                    break;
                case 2:
                    state = @"3G";
                    break;
                case 3:
                    state = @"4G";
                    break;
                case 5:
                    state = @"WIFI";
                    break;
                default:
                    break;
            }
        }
    }
    SADebug(@"network=%@", state);
    return state;
}

@end

@implementation SensorsAnalyticsPeople {
    SensorsAnalyticsSDK *_sdk;
}


- (id)initWithSDK:(SensorsAnalyticsSDK *)sdk {
    self = [super init];
    if (self) {
        _sdk = sdk;
    }
    return self;
}

- (void)set:(NSDictionary *)profileDict {
    NSLog(@"set profileDict");
    [_sdk track:nil withProperties:profileDict withType:@"profile_set"];
}

- (void)setOnce:(NSDictionary *)profileDict {
    NSLog(@"setOnce profileDict");
    [_sdk track:nil withProperties:profileDict withType:@"profile_set_once"];
}

- (void)set:(NSString *) profile to:(id)content {
    [_sdk track:nil withProperties:@{profile: content} withType:@"profile_set"];
}

- (void)setOnce:(NSString *) profile to:(id)content {
    [_sdk track:nil withProperties:@{profile: content} withType:@"profile_set_once"];
}

- (void)unset:(NSString *) profile {
    [_sdk track:nil withProperties:@{profile: @""} withType:@"profile_unset"];
}

- (void)increment:(NSString *)profile by:(NSNumber *)amount {
    [_sdk track:nil withProperties:@{profile: amount} withType:@"profile_increment"];
}

- (void)increment:(NSDictionary *)profileDict {
    // 做一下类型校验，key必须是NSString，Value必须是NSNumber
    id key;
    id value;
    for (key in profileDict) {
        value = profileDict[key];
        if (![key isKindOfClass:[NSString class]]) {
            NSString * errMsg = [NSString stringWithFormat: @"increment key must be NSString. got: %@ %@", [key class], key];
            @throw [SensorsAnalyticsException exceptionWithName:@"InvalidDataException" reason:errMsg userInfo:nil];
        }
        if (![value isKindOfClass:[NSNumber class]]) {
            NSString * errMsg = [NSString stringWithFormat:@"increment value must be NSNumber. got: %@ %@", [value class], value];
            @throw [SensorsAnalyticsException exceptionWithName:@"InvalidDataException" reason:errMsg userInfo:nil];
        }
    }
    [_sdk track:nil withProperties:profileDict withType:@"profile_increment"];
}

- (void)append:(NSString *)profile by:(NSSet *)content {
    // 做一下类型校验，append所添加的数组中只能是NSString
    NSEnumerator *enumerator = [content objectEnumerator];
    id object;
    while (object = [enumerator nextObject]) {
        if (![object isKindOfClass:[NSString class]]) {
            NSString * errMsg = [NSString stringWithFormat:@"append value must be NSString. got: %@ %@", [object class], object];
            @throw [SensorsAnalyticsException exceptionWithName:@"InvalidDataException" reason:errMsg userInfo:nil];
        }
    }
    [_sdk track:nil withProperties:@{profile: content} withType:@"profile_append"];
}

- (void)deleteUser {
    [_sdk track:nil withProperties:@{} withType:@"profile_delete"];
}

@end
